#!/bin/bash

source ./logging.sh

# shellcheck disable=SC2086 # intentional word splitting for extra args
run_with_logging "Tempo ${TEMPO_VERSION}" "${ENABLE_LOGS_TEMPO:-false}" \
	./tempo/tempo --config.file=./tempo-config.yaml ${TEMPO_EXTRA_ARGS:-}
