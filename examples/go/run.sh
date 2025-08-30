#!/bin/bash

set -euo pipefail

export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,service.instance.id=127.0.0.1:8081"

# Run the application
# use http instead of https (needed because of https://github.com/open-telemetry/opentelemetry-go/issues/4834)
export OTEL_EXPORTER_OTLP_INSECURE="true"
go run .
