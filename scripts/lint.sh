#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Fix markdownlint issues"
markdownlint -f -i container -i examples/python/venv .

echo "Check links"
lychee .

echo "Run Super-Linter"
docker run \
  -e LOG_LEVEL=DEBUG \
  -e RUN_LOCAL=true \
  -v .:/tmp/lint \
  ghcr.io/super-linter/super-linter:latest
