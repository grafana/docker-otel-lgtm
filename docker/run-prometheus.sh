#!/bin/bash

source ./logging.sh

# shellcheck disable=SC2086 # intentional word splitting for extra args
run_with_logging "Prometheus ${PROMETHEUS_VERSION}" "${ENABLE_LOGS_PROMETHEUS:-false}" ./prometheus/prometheus \
	--web.enable-remote-write-receiver \
	--web.enable-otlp-receiver \
	--enable-feature=exemplar-storage \
	--storage.tsdb.path=/data/prometheus \
	--config.file=./prometheus.yaml \
	${PROMETHEUS_EXTRA_ARGS:-}
