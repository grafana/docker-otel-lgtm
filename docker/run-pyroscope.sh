#!/bin/bash

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling logging.sh

mkdir -p /data/pyroscope

extra_args=()
if [[ -n "${PYROSCOPE_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${PYROSCOPE_EXTRA_ARGS}"
fi
run_with_logging "Pyroscope ${PYROSCOPE_VERSION}" "${ENABLE_LOGS_PYROSCOPE:-false}" \
	./pyroscope/pyroscope --config.file=./pyroscope-config.yaml "${extra_args[@]}"
