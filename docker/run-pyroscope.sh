#!/bin/bash

source ./logging.sh

mkdir -p /data/pyroscope

read -ra extra_args <<<"${PYROSCOPE_EXTRA_ARGS:-}"
run_with_logging "Pyroscope ${PYROSCOPE_VERSION}" "${ENABLE_LOGS_PYROSCOPE:-false}" \
	./pyroscope/pyroscope --config.file=./pyroscope-config.yaml "${extra_args[@]}"
