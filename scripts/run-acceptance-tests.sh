#!/usr/bin/env bash

set -euo pipefail

version=${1:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

./build-lgtm.sh "$version"
oats -timeout 5m -lgtm-version "$version" examples/
