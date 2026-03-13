#!/bin/bash

source ./logging.sh

mkdir -p /data/loki

extra_args=()
if [[ -n "${LOKI_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${LOKI_EXTRA_ARGS}"
fi
run_with_logging "Loki ${LOKI_VERSION}" "${ENABLE_LOGS_LOKI:-false}" \
	./loki/loki --config.file=./loki-config.yaml "${extra_args[@]}"
