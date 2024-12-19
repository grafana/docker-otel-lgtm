#!/usr/bin/env bash

set -euo pipefail

dir="$(dirname "$0")"

pushd "$dir/.."

echo "Check links"
lychee --cache --include-fragments .

popd

echo "Run Super-Linter"
"$dir"/super-linter.sh
