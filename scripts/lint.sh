#!/usr/bin/env bash

set -euo pipefail

dir="$(dirname "$0")"

pushd "$dir/.."

echo "Fix markdownlint issues"
markdownlint -f -i container -i examples/python/venv .

echo "Check links"
lychee --cache .

popd

echo "Run Super-Linter"
"$dir"/super-linter.sh
