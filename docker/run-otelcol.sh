#!/bin/bash

source ./logging.sh

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" ./otelcol-contrib/otelcol-contrib --config=file:./otelcol-config.yaml
