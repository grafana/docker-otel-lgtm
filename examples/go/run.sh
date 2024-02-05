#!/bin/bash

set -euo pipefail

export OTEL_EXPORTER_OTLP_INSECURE="true" # needed because of https://github.com/open-telemetry/opentelemetry-go/issues/4834
export OTEL_METRIC_EXPORT_INTERVAL="5000"  # so we don't have to wait 60s for metrics
export OTEL_RESOURCE_ATTRIBUTES="service.name=example-app,service.instance.id=localhost:8081"
go run .
