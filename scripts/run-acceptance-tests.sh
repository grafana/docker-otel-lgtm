#!/usr/bin/env bash

set -euo pipefail

cp mise.* ../oats
cd ../oats/yaml
ginkgo
