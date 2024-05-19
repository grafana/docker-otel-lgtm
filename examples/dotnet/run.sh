#!/bin/bash

set -euo pipefail

export OTEL_METRIC_EXPORT_INTERVAL="5000"  # so we don't have to wait 60s for metrics
dotnet run