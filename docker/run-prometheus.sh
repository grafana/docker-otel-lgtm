#!/bin/bash

source ./logging.sh

# Prometheus retention settings
export PROM_RETENTION_TIME="${PROM_RETENTION_TIME:-}"
export PROM_RETENTION_SIZE="${PROM_RETENTION_SIZE:-}"

PROM_ARGS=(
	--web.enable-remote-write-receiver
	--web.enable-otlp-receiver
	--enable-feature=exemplar-storage
	--storage.tsdb.path=/data/prometheus
	--config.file=./prometheus.yaml
)

# Optional time-based retention
if [ -n "${PROM_RETENTION_TIME:-}" ]; then
	PROM_ARGS+=(--storage.tsdb.retention.time="${PROM_RETENTION_TIME}")
fi

# Optional size-based retention
if [ -n "${PROM_RETENTION_SIZE:-}" ]; then
	PROM_ARGS+=(--storage.tsdb.retention.size="${PROM_RETENTION_SIZE}")
fi

run_with_logging "Prometheus ${PROMETHEUS_VERSION}" "${ENABLE_LOGS_PROMETHEUS:-false}" \
	./prometheus/prometheus "${PROM_ARGS[@]}"
