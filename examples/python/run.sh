#!/bin/bash

set -euo pipefail

export OTEL_METRIC_EXPORT_INTERVAL="5000" # so we don't have to wait 60s for metrics
export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,service.instance.id=127.0.0.1:8082"

python3 -m venv venv
# shellcheck disable=SC1091
source ./venv/bin/activate

# How to get the requirements.txt file?
# 1. Follow https://opentelemetry.io/docs/languages/python/getting-started/
# 2. Run `pip freeze > requirements.txt` in the same directory as your app.py file
pip install --upgrade pip
pip install -r requirements.txt

# Step 1: Install the OpenTelemetry SDK
# renovate: datasource=pypi depName=opentelemetry-distro
opentelemetry_distro_version=0.60b0
pip install "opentelemetry-distro[otlp]==${opentelemetry_distro_version}"
opentelemetry-bootstrap -a install

# Step 2: Run the application
export OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
export OTEL_LOGS_EXPORTER=otlp
opentelemetry-instrument flask run -p 8082
