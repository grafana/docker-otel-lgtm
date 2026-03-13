#!/bin/bash

source ./logging.sh

mkdir -p /data/pyroscope

extra_args=()
if [[ -n "${PYROSCOPE_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${PYROSCOPE_EXTRA_ARGS}"
fi
run_with_logging "Pyroscope ${PYROSCOPE_VERSION}" "${ENABLE_LOGS_PYROSCOPE:-false}" \
	./pyroscope/pyroscope --config.file=./pyroscope-config.yaml "${extra_args[@]}"
