#!/bin/bash

source ./logging.sh

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
