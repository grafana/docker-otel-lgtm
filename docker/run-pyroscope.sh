#!/bin/bash

source ./logging.sh

mkdir -p /data/pyroscope

# shellcheck disable=SC2086 # intentional word splitting for extra args
run_with_logging "Pyroscope ${PYROSCOPE_VERSION}" "${ENABLE_LOGS_PYROSCOPE:-false}" \
	./pyroscope/pyroscope --config.file=./pyroscope-config.yaml ${PYROSCOPE_EXTRA_ARGS:-}
