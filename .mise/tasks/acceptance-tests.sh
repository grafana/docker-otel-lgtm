#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

version=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

# Force Docker: oats hardcodes `docker compose`, so the image must be built with Docker.
./build-lgtm.sh "$version" docker

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

git clone --depth 1 --branch v2 https://github.com/grafana/oats "$workdir/oats-src"
chmod +x "$workdir/oats-src/scripts/build-local-tools.sh"
"$workdir/oats-src/scripts/build-local-tools.sh" "$workdir/bin"

export LGTM_IMAGE="grafana/otel-lgtm:${version}"
"$workdir/bin/oats" \
	--config oats.toml \
	--gcx "$workdir/bin/gcx" \
	--no-cache \
	--timeout=3m \
	-v 2
