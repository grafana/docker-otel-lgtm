#!/usr/bin/env bash

set -euo pipefail

# git clone https://github.com/grafana/oats.git
cd oats/yaml
go install github.com/onsi/ginkgo/v2/ginkgo@latest
export TESTCASE_TIMEOUT=1m
export TESTCASE_BASE_PATH=../../examples/dotnet
ginkgo -r
