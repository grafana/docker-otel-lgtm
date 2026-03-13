#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

version=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

# Force Docker: oats hardcodes `docker compose`, so the image must be built with Docker.
mise run build-lgtm "$version" docker
oats -timeout 5m -lgtm-version "$version" examples/
