#!/bin/bash

source ./logging.sh

mkdir -p /data/loki

# shellcheck disable=SC2086 # intentional word splitting for extra args
run_with_logging "Loki ${LOKI_VERSION}" "${ENABLE_LOGS_LOKI:-false}" \
	./loki/loki --config.file=./loki-config.yaml ${LOKI_EXTRA_ARGS:-}
