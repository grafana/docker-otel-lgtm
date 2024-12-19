#!/usr/bin/env bash

set -euo pipefail

files=$(find examples -name "lgtm.yaml")
for file in $files; do
	sed -i 's#.*image: grafana/otel-lgtm:latest.*#&\n          imagePullPolicy: Never#' "$file"
done

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
example_dir=$(pwd)/examples
export TESTCASE_TIMEOUT=5m
export TESTCASE_BASE_PATH=$example_dir

cd ../oats/yaml
go install github.com/onsi/ginkgo/v2/ginkgo@latest
ginkgo
