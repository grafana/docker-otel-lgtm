#!/bin/bash

./run-grafana.sh &
./run-loki.sh &
./run-otelcol.sh &
./run-prometheus.sh &
./run-tempo.sh &

echo "Waiting for the OpenTelemetry collector and the Grafana LGTM stack to start up..."

function wait_ready() {
  service=$1
  url=$2

  while [[ $(curl -o /dev/null -sg "${url}" -w "%{response_code}") != "200" ]] ; do
    echo "Waiting for ${service} to start up..."
    sleep 1
  done
  echo "${service} is up and running."
}

wait_ready "Grafana" "http://localhost:3000/api/health"
wait_ready "Loki" "http://localhost:3100/ready"
wait_ready "Prometheus" "http://localhost:9090/api/v1/status/runtimeinfo"
wait_ready "Tempo" "http://localhost:3200/ready"

# collector may not have a prometheus endpoint exposed if the config has been replaced,
# so we query the otelcol_process_uptime_total metric instead, which checks if the collector is up,
# and indirectly checks if the prometheus endpoint is up.
while ! curl -sg 'http://localhost:9090/api/v1/query?query=otelcol_process_uptime_total{}' | jq -r .data.result[0].value[1] | grep '[0-9]' > /dev/null ; do
  echo "Waiting for the OpenTelemetry collector to start up..."
  sleep 1
done

touch /tmp/ready
echo "The OpenTelemetry collector and the Grafana LGTM stack are up and running. (created /tmp/ready)"

echo "Open ports:"
echo " - 4317: OpenTelemetry GRPC endpoint"
echo " - 4318: OpenTelemetry HTTP endpoint"
echo " - 3000: Grafana. User: admin, password: admin"

sleep infinity
