#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

LGTM_VERSION=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $LGTM_VERSION"

# Build with Docker so the image is available when OATS falls back to Docker.
./build-lgtm.sh "$LGTM_VERSION" docker

export OATS_PARALLEL=${OATS_PARALLEL:-4}

# Capture the same short version probe used by OATS before it runs. This makes
# runner-specific gcx failures diagnosable without changing OATS' behavior.
echo "gcx resolved path: $(command -v gcx || echo 'not found')"
if command -v timeout >/dev/null && command -v gcx >/dev/null; then
	probe_dir=$(mktemp -d)
	trap 'rm -rf "$probe_dir"' EXIT
	probe_started=$SECONDS
	set +e
	timeout --kill-after=1s 3s gcx --version >"$probe_dir/stdout" 2>"$probe_dir/stderr"
	gcx_status=$?
	set -e
	probe_elapsed=$((SECONDS - probe_started))
	echo "gcx --version exit status: $gcx_status (elapsed ${probe_elapsed}s)"
	echo "gcx --version stdout:"
	cat "$probe_dir/stdout"
	echo "gcx --version stderr:"
	cat "$probe_dir/stderr" >&2
else
	echo "gcx version probe skipped (timeout or gcx is unavailable)"
fi

oats \
	--no-cache \
	--lgtm-version "$LGTM_VERSION" \
	--timeout=5m \
	.
