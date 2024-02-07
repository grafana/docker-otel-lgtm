#!/bin/bash

set -euo pipefail

export OTEL_METRIC_EXPORT_INTERVAL="5000"  # so we don't have to wait 60s for metrics
export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,service.instance.id=localhost:8082"

python3 -m venv venv
source ./venv/bin/activate

# How to get the requirements.txt file?
# 1. Follow https://opentelemetry.io/docs/languages/python/getting-started/
# 2. Run `pip freeze > requirements.txt` in the same directory as your app.py file
pip install -r requirements.txt

pip install opentelemetry-distro[otlp]
opentelemetry-bootstrap -a install

export OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
opentelemetry-instrument flask run -p 8082
