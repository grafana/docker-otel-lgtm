#!/bin/bash

source ./logging.sh

read -ra extra_args <<<"${TEMPO_EXTRA_ARGS:-}"
run_with_logging "Tempo ${TEMPO_VERSION}" "${ENABLE_LOGS_TEMPO:-false}" \
	./tempo/tempo --config.file=./tempo-config.yaml "${extra_args[@]}"
