#!/bin/bash

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling logging.sh

extra_args=()
if [[ -n "${TEMPO_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${TEMPO_EXTRA_ARGS}"
fi
run_with_logging "Tempo ${TEMPO_VERSION}" "${ENABLE_LOGS_TEMPO:-false}" \
	./tempo/tempo --config.file=./tempo-config.yaml "${extra_args[@]}"
