#!/bin/bash

source ./logging.sh

config_file="otelcol-config.yaml"

if [[ ${OTEL_EXPORTER_OTLP_ENDPOINT:-} != "-" ]]; then
  echo "Also enabling OTLP exporter to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
  config_file="otelcol-config-local-and-remote.yaml"
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" ./otelcol-contrib/otelcol-contrib --config=file:./${config_file}
