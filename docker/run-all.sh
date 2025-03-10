#!/bin/bash

# Record global start time
start_time_global=$(date +%s)

# Function to record start time for a component
start_component() {
	local component=$1
	local start_time=$(date +%s)
	# Store start time in an associative array
	eval "start_time_${component}=${start_time}"
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

echo "Waiting for all components to start up..."

# Declare arrays to store service status and elapsed times
declare -A service_ready elapsed_times

# Define services and their health check URLs
declare -A services
services["grafana"]="http://localhost:3000/api/health"
services["loki"]="http://localhost:3100/ready"
services["prometheus"]="http://localhost:9090/api/v1/status/runtimeinfo"
services["tempo"]="http://localhost:3200/ready"

# Initialize service_ready status to false for all services
for service in "${!services[@]}"; do
	service_ready[$service]=false
done

# Also check OpenTelemetry collector separately (since it uses a different check method)
service_ready["otelcol"]=false

# Function to check if a service is ready
check_service_ready() {
	local service=$1
	local url=$2

	# Skip if service is already marked as ready
	if [[ ${service_ready[$service]} == true ]]; then
		return 0
	fi

	# Check if service is ready
	if [[ $(curl -o /dev/null -sg "${url}" -w "%{response_code}" 2>/dev/null) == "200" ]]; then
		# Calculate and display startup time
		end_time=$(date +%s)
		start_var="start_time_${service}"
		start_time=$(eval echo \${$start_var})
		elapsed=$((end_time - start_time))
		# Store the elapsed time in the array
		elapsed_times[$service]=$elapsed
		service_ready[$service]=true
		echo "${service^} is up and running. Startup time: ${elapsed} seconds"
		return 0
	fi

	return 1
}

# Function to check if OpenTelemetry collector is ready
check_otelcol_ready() {
	# Skip if already marked as ready
	if [[ ${service_ready["otelcol"]} == true ]]; then
		return 0
	fi

	# Check if collector is ready via Prometheus metric
	if curl -sg 'http://localhost:9090/api/v1/query?query=otelcol_process_uptime_total{}' 2>/dev/null | jq -r .data.result[0].value[1] 2>/dev/null | grep '[0-9]' >/dev/null; then
		# Calculate and display startup time
		end_time=$(date +%s)
		otelcol_start_time=${start_time_otelcol}
		elapsed=$((end_time - otelcol_start_time))
		elapsed_times["otelcol"]=$elapsed
		service_ready["otelcol"]=true
		echo "OpenTelemetry collector is up and running. Startup time: ${elapsed} seconds"
		return 0
	fi

	return 1
}

# Wait for all services to be ready
all_ready=false
while [[ $all_ready == false ]]; do
	# Check each service
	for service in "${!services[@]}"; do
		check_service_ready "$service" "${services[$service]}"
	done

	# Check OpenTelemetry collector
	check_otelcol_ready

	# Check if all services are ready
	all_ready=true
	for service in "${!service_ready[@]}"; do
		if [[ ${service_ready[$service]} == false ]]; then
			all_ready=false
			break
		fi
	done

	# If not all ready, wait a second before trying again
	if [[ $all_ready == false ]]; then
		sleep 1
	fi
done

# Calculate total startup time
end_time_global=$(date +%s)
total_elapsed=$((end_time_global - start_time_global))

touch /tmp/ready
echo "All components are up and running. (created /tmp/ready)"
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
