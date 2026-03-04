#!/bin/bash

source ./logging.sh

run_with_logging "Prometheus ${PROMETHEUS_VERSION}" "${ENABLE_LOGS_PROMETHEUS:-false}" ./prometheus/prometheus \
	--web.enable-remote-write-receiver \
	--web.enable-otlp-receiver \
	--enable-feature=exemplar-storage \
	--storage.tsdb.path=/data/prometheus \
	--config.file=./prometheus.yaml
