#!/bin/bash

source ./logging.sh

extra_args=()
if [[ -n "${TEMPO_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${TEMPO_EXTRA_ARGS}"
fi
run_with_logging "Tempo ${TEMPO_VERSION}" "${ENABLE_LOGS_TEMPO:-false}" \
	./tempo/tempo --config.file=./tempo-config.yaml "${extra_args[@]}"
