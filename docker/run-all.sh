#!/bin/bash

# Record global start time
start_time_global=$(date +%s)

# Function to record start time for a component
start_component() {
	local component=$1
	local start_time=$(date +%s)
	# Store start time in an associative array
	eval "start_time_${component}=${start_time}"
	echo "Starting ${component}..."
}

# Start all components and record their start times
start_component "grafana"
./run-grafana.sh &

start_component "loki"
./run-loki.sh &

start_component "otelcol"
./run-otelcol.sh &

start_component "prometheus"
./run-prometheus.sh &

start_component "tempo"
./run-tempo.sh &

echo "Waiting for the OpenTelemetry collector and the Grafana LGTM stack to start up..."

# Declare an array to store elapsed times
declare -A elapsed_times

function wait_ready() {
	service=$1
	url=$2
	service_key=$(echo "$service" | tr '[:upper:]' '[:lower:]')

	while [[ $(curl -o /dev/null -sg "${url}" -w "%{response_code}") != "200" ]]; do
		echo "Waiting for ${service} to start up..."
		sleep 1
	done

	# Calculate and display startup time
	end_time=$(date +%s)
	start_var="start_time_${service_key}"
	start_time=$(eval echo \${$start_var})
	elapsed=$((end_time - start_time))
	# Store the elapsed time in the array
	elapsed_times[$service_key]=$elapsed
	echo "${service} is up and running. Startup time: ${elapsed} seconds"
}

wait_ready "Grafana" "http://localhost:3000/api/health"
wait_ready "Loki" "http://localhost:3100/ready"
wait_ready "Prometheus" "http://localhost:9090/api/v1/status/runtimeinfo"
wait_ready "Tempo" "http://localhost:3200/ready"

# Record start time for OpenTelemetry check if not already done
otelcol_start_time=${start_time_otelcol}

# we query the otelcol_process_uptime_total metric instead, which checks if the collector is up,
# and indirectly checks if the prometheus endpoint is up.
while ! curl -sg 'http://localhost:9090/api/v1/query?query=otelcol_process_uptime_total{}' | jq -r .data.result[0].value[1] | grep '[0-9]' >/dev/null; do
	echo "Waiting for the OpenTelemetry collector to start up..."
	sleep 1
done

# Calculate and display OpenTelemetry collector startup time
otelcol_end_time=$(date +%s)
otelcol_elapsed=$((otelcol_end_time - otelcol_start_time))
elapsed_times[otelcol]=$otelcol_elapsed
echo "OpenTelemetry collector is up and running. Startup time: ${otelcol_elapsed} seconds"

# Calculate total startup time
end_time_global=$(date +%s)
total_elapsed=$((end_time_global - start_time_global))

touch /tmp/ready
echo "The OpenTelemetry collector and the Grafana LGTM stack are up and running. (created /tmp/ready)"
echo "Total startup time: ${total_elapsed} seconds"

echo "Open ports:"
echo " - 4317: OpenTelemetry GRPC endpoint"
echo " - 4318: OpenTelemetry HTTP endpoint"
echo " - 3000: Grafana. User: admin, password: admin"

# Print startup time summary
echo -e "\nStartup Time Summary:"
echo "---------------------"
echo "Grafana: ${elapsed_times[grafana]} seconds"
echo "Loki: ${elapsed_times[loki]} seconds"
echo "Prometheus: ${elapsed_times[prometheus]} seconds"
echo "Tempo: ${elapsed_times[tempo]} seconds"
echo "OpenTelemetry collector: ${elapsed_times[otelcol]} seconds"
echo "Total: ${total_elapsed} seconds"

sleep infinity
