#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

LGTM_VERSION=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $LGTM_VERSION"

# Build with Docker so the image is available when OATS falls back to Docker.
./build-lgtm.sh "$LGTM_VERSION" docker

export OATS_PARALLEL=${OATS_PARALLEL:-4}

oats \
	--no-cache \
	--lgtm-version "$LGTM_VERSION" \
	--timeout=5m \
	.
