#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

version=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

# Build with Docker so the image is available when OATS falls back to Docker.
./build-lgtm.sh "$version" docker

export LGTM_IMAGE="grafana/otel-lgtm:${version}"
oats \
	--config oats-config.yaml \
	--no-cache \
	--timeout=3m
