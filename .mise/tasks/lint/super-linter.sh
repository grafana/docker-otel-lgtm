#!/usr/bin/env bash
#MISE description="Run Super-Linter on the repository - applying auto-fixes unless disabled with --no-fix"
#USAGE flag "--no-fix" help="Disable auto-fix (for CI)"

set -euo pipefail

# check for required env vars, otherwise exit with error
if [ -z "${SUPER_LINTER_VERSION:-}" ]; then
	echo "SUPER_LINTER_VERSION environment variable is not set. Exiting."
	exit 1
fi

if [ -z "${MISE_PROJECT_ROOT:-}" ]; then
	echo "MISE_PROJECT_ROOT environment variable is not set. Exiting."
	exit 1
fi

cd "${MISE_PROJECT_ROOT}"

if command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
	# Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
	# See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
	# See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
	MOUNT_OPTS="rw,z"
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
	MOUNT_OPTS=rw
else
	echo "Unable to find a suitable container runtime such as Podman or Docker. Exiting."
	exit 1
fi

ENV_FILE=".github/config/super-linter.env"
no_fix="${usage_no_fix:-${CI:-false}}"
if [ "$no_fix" = "true" ]; then
	# Filter out FIX_* and comment lines for CI mode
	FILTERED_ENV_FILE=$(mktemp)
	trap 'rm -f "$FILTERED_ENV_FILE"' EXIT
	grep -v '^#' "$ENV_FILE" | grep -v '^FIX_' >"$FILTERED_ENV_FILE"
	ENV_FILE="$FILTERED_ENV_FILE"
fi

$RUNTIME image pull -q --platform linux/amd64 "ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}" >/dev/null

$RUNTIME container run --rm --platform linux/amd64 \
	-e RUN_LOCAL=true \
	-e DEFAULT_BRANCH=main \
	--env-file "$ENV_FILE" \
	-v "$(pwd)":/tmp/lint:"${MOUNT_OPTS}" \
	"ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"
