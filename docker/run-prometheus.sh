#!/bin/bash

source ./logging.sh

PROM_ARGS=(
	--web.enable-remote-write-receiver
	--web.enable-otlp-receiver
	--enable-feature=exemplar-storage
	--storage.tsdb.path=/data/prometheus
	--config.file=./prometheus.yaml
)

if [ -n "${PROM_RETENTION_TIME:-}" ]; then
	PROM_ARGS+=(--storage.tsdb.retention.time="${PROM_RETENTION_TIME}")
fi

if [ -n "${PROM_RETENTION_SIZE:-}" ]; then
	PROM_ARGS+=(--storage.tsdb.retention.size="${PROM_RETENTION_SIZE}")
fi

run_with_logging "Prometheus ${PROMETHEUS_VERSION}" "${ENABLE_LOGS_PROMETHEUS:-false}" \
	./prometheus/prometheus "${PROM_ARGS[@]}"
