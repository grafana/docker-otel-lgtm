#!/bin/bash

source ./logging.sh

config_file="otelcol-config.yaml"

#if [[ [[ ! -v variable ]] ${GRAFANA_CLOUD_ZONE:-} != "-" ]]; then
if [[ -v GRAFANA_CLOUD_ZONE ]]; then
  if [[ ! -v GRAFANA_CLOUD_INSTANCE_ID ]]; then
    echo "Please set GRAFANA_CLOUD_INSTANCE_ID to the instance ID of your Grafana Cloud instance"
    exit 1
  fi
  if [[ ! -v GRAFANA_CLOUD_API_KEY ]]; then
    echo "Please set GRAFANA_CLOUD_API_KEY to the zone of your Grafana Cloud instance"
    exit 1
  fi

  echo "Also enabling Grafana Cloud export to ${GRAFANA_CLOUD_ZONE} with instance ID ${GRAFANA_CLOUD_INSTANCE_ID}"

  config_file="otelcol-config-grafana-cloud.yaml"
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" ./otelcol-contrib/otelcol-contrib --config=file:./${config_file}
