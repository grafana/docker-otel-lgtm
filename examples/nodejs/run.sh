#!/bin/bash

set -euo pipefail

export OTEL_METRIC_EXPORT_INTERVAL="5000" # so we don't have to wait 60s for metrics
export OTEL_METRIC_EXPORT_TIMEOUT="5000"  # so we don't have to wait 60s for metrics
export OTEL_SERVICE_NAME="dice-server"
export OTEL_SERVICE_VERSION="0.1.0"

npm install

npm start
