#!/usr/bin/env bash

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling logging.sh

mkdir -p /data/loki

extra_args=()
if [[ -n "${LOKI_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${LOKI_EXTRA_ARGS}"
fi
run_with_logging "Loki ${LOKI_VERSION}" "${ENABLE_LOGS_LOKI:-false}" \
	./loki/loki --config.file=./loki-config.yaml "${extra_args[@]}"
