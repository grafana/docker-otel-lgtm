#!/bin/bash

set -euo pipefail

export OTEL_EXPORTER_OTLP_INSECURE="true"
export OTEL_METRIC_EXPORT_INTERVAL="5000"  # so we don't have to wait 60s for metrics
export OTEL_RESOURCE_ATTRIBUTES="service.name=example-app,service.instance.id=localhost:8080"
go run .
