#!/bin/bash

./run-grafana.sh &
./run-loki.sh &
./run-otelcol.sh &
./run-prometheus.sh &
./run-tempo.sh &

echo "Open ports:"
echo " - 4317: OpenTelemetry endpoint"
echo " - 3000: Grafana. User: admin, password: admin"
echo "It might take a minute for all services to start up"

sleep infinity
