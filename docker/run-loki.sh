#!/bin/bash

source ./logging.sh

mkdir -p /data/loki

read -ra extra_args <<< "${LOKI_EXTRA_ARGS:-}"
run_with_logging "Loki ${LOKI_VERSION}" "${ENABLE_LOGS_LOKI:-false}" \
	./loki/loki --config.file=./loki-config.yaml "${extra_args[@]}"
