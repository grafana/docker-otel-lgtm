#!/usr/bin/env bash

set -euo pipefail

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
cd oats/yaml
go install github.com/onsi/ginkgo/v2/ginkgo@latest
export TESTCASE_TIMEOUT=5m
export TESTCASE_BASE_PATH=../../examples
ginkgo -r
