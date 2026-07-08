#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

version=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

# Force Docker: oats hardcodes `docker compose`, so the image must be built with Docker.
./build-lgtm.sh "$version" docker

export LGTM_IMAGE="grafana/otel-lgtm:${version}"
oats \
	--config oats.toml \
	--gcx "$(command -v gcx)" \
	--no-cache \
	--parallel 4 \
	--timeout=3m \
	-v 2
