#!/bin/bash

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling logging.sh

extra_args=()
if [[ -n "${PROMETHEUS_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${PROMETHEUS_EXTRA_ARGS}"
fi
run_with_logging "Prometheus ${PROMETHEUS_VERSION}" "${ENABLE_LOGS_PROMETHEUS:-false}" ./prometheus/prometheus \
	--web.enable-remote-write-receiver \
	--web.enable-otlp-receiver \
	--enable-feature=exemplar-storage \
	--storage.tsdb.path=/data/prometheus \
	--config.file=./prometheus.yaml \
	"${extra_args[@]}"
