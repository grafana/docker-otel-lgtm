#!/usr/bin/env bash

set -euo pipefail

RELEASE=${1:-latest}

files=$(find examples -name "lgtm.yaml")
for file in $files; do
	sed -i 's#.*image: grafana/otel-lgtm:latest.*#&\n          imagePullPolicy: Never#' "$file"
done

example_dir=$(pwd)/examples
export TESTCASE_TIMEOUT=5m
export TESTCASE_BASE_PATH=$example_dir
export LGTM_VERSION=$RELEASE

cp mise.* ../oats
cd ../oats/yaml
ginkgo
