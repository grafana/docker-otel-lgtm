#!/usr/bin/env bash

READY_FILE=${LGTM_READY_FILE:-/tmp/ready}
rm -f "$READY_FILE"

echo "Starting grafana/otel-lgtm ${LGTM_VERSION}"

# Stop any still-running backgrounded components, giving them time to stop
# cleanly before forcing any stragglers down. Used both for SIGTERM/SIGINT
# and when a component fails to start, so a startup failure doesn't leak
# orphaned processes.
stop_components() {
	local pids=()
	mapfile -t pids < <(jobs -pr)
	if ((${#pids[@]} == 0)); then
		return 0
	fi

	# The wrapper scripts exec the server processes, so these are the server
	# PIDs. Give them time to stop cleanly before forcing any stragglers down.
	kill -TERM "${pids[@]}" 2>/dev/null || true
	(
		sleep "${LGTM_SHUTDOWN_TIMEOUT_SECONDS:-5}"
		kill -KILL "${pids[@]}" 2>/dev/null || true
	) &
	local watchdog_pid=$!

	wait "${pids[@]}" 2>/dev/null || true
	kill "$watchdog_pid" 2>/dev/null || true
	wait "$watchdog_pid" 2>/dev/null || true
}

# Graceful shutdown: forward SIGTERM/SIGINT to all background jobs.
shutdown() {
	# Avoid re-entering the handler if another signal arrives while waiting.
	trap - SIGTERM SIGINT
	echo "Shutting down..."
	stop_components
	exit 0
}
trap shutdown SIGTERM SIGINT

# Record global start time
start_time_global=$(date +%s)

# Function to record start time for a component
start_component() {
	local component=$1
	local start_time
	start_time=$(date +%s)
	# Store start time in an associative array
	eval "start_time_${component}=${start_time}"
}

# Start all components and record their start times, keeping the PID of
# each so a component that exits before it becomes ready can be detected.
declare -A component_pids

start_component "grafana"
./run-grafana.sh &
component_pids[grafana]=$!

start_component "loki"
./run-loki.sh &
component_pids[loki]=$!

start_component "otelcol"
./run-otelcol.sh &
component_pids[otelcol]=$!

start_component "prometheus"
./run-prometheus.sh &
component_pids[prometheus]=$!

start_component "tempo"
./run-tempo.sh &
component_pids[tempo]=$!

start_component "pyroscope"
./run-pyroscope.sh &
component_pids[pyroscope]=$!

if [[ ${ENABLE_OBI:-false} == "true" ]]; then
	start_component "obi"
	./run-obi.sh &
fi

echo "Waiting for the OpenTelemetry collector and the Grafana LGTM stack to start up..."

# Declare arrays to store service status and elapsed times
declare -A service_ready elapsed_times

# Define services and their health check URLs
declare -A services
services["grafana"]="http://127.0.0.1:3000/api/health"
services["loki"]="http://127.0.0.1:3100/ready"
services["prometheus"]="http://127.0.0.1:9090/api/v1/status/runtimeinfo"
services["tempo"]="http://127.0.0.1:3200/ready"
services["pyroscope"]="http://127.0.0.1:4040/ready"
services["otelcol"]="http://127.0.0.1:13133/ready"

# Initialize service_ready status to false for all services
for service in "${!services[@]}"; do
	service_ready[$service]=false
done

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
		# shellcheck disable=SC1083,SC2086
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

# Function to check if a component's process is still among the running
# background jobs (as opposed to having already exited).
pid_is_running() {
	local target=$1
	local pid
	for pid in "${running_pids[@]}"; do
		[[ ${pid} == "${target}" ]] && return 0
	done
	return 1
}

# Wait for all services to be ready
all_ready=false
while [[ $all_ready == false ]]; do
	# Check each service
	for service in "${!services[@]}"; do
		check_service_ready "$service" "${services[$service]}"
	done

	# Fail fast if a component's process has already exited, rather than
	# waiting forever for a health check that will never succeed.
	mapfile -t running_pids < <(jobs -pr)
	for service in "${!services[@]}"; do
		if [[ ${service_ready[$service]} == false ]] && ! pid_is_running "${component_pids[$service]}"; then
			echo "Error: ${service^} exited before becoming ready." >&2
			echo "Re-run with ENABLE_LOGS_${service^^}=true (or ENABLE_LOGS_ALL=true) to see its output." >&2
			stop_components
			exit 1
		fi
	done

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

echo "Total startup time: ${total_elapsed} seconds"

# Print startup time summary
echo -e "\nStartup Time Summary:"
echo "---------------------"
echo "Grafana: ${elapsed_times[grafana]} seconds"
echo "Loki: ${elapsed_times[loki]} seconds"
echo "Prometheus: ${elapsed_times[prometheus]} seconds"
echo "Tempo: ${elapsed_times[tempo]} seconds"
echo "Pyroscope: ${elapsed_times[pyroscope]} seconds"
echo "OpenTelemetry collector: ${elapsed_times[otelcol]} seconds"
if [[ ${ENABLE_OBI:-false} == "true" ]]; then
	echo "OBI: (opt-in, not in health check)"
fi
echo "Total: ${total_elapsed} seconds"

touch "$READY_FILE"
echo "The OpenTelemetry collector and the Grafana LGTM stack are up and running. (created $READY_FILE)"

# One local-first next step; gcx and agent skills run on the host.
echo ""
echo "Query and troubleshoot telemetry with gcx:"
docs_ref="main"
if [[ "${LGTM_VERSION}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
	docs_ref="${LGTM_VERSION}"
	[[ "${docs_ref}" != v* ]] && docs_ref="v${docs_ref}"
fi
echo "  https://github.com/grafana/docker-otel-lgtm/blob/${docs_ref}/docs/gcx-integration.md"

if [[ ${ENABLE_OBI:-false} == "true" ]]; then
	# Non-blocking check — don't delay readiness if OBI fails (e.g. missing capabilities)
	if curl -o /dev/null -sg "http://127.0.0.1:6060/metrics" -w "%{response_code}" 2>/dev/null | grep -q "200"; then
		echo "OBI is up and running."
	else
		echo "Warning: OBI internal metrics endpoint is not responding. This may indicate missing eBPF capabilities (--pid=host --privileged)."
	fi
	if [[ -n ${OBI_TARGET:-} ]]; then
		echo "OBI: monitoring '${OBI_TARGET}' processes"
	elif [[ -n ${OTEL_EBPF_AUTO_TARGET_EXE:-} ]]; then
		echo "OBI: monitoring processes matching executable name '${OTEL_EBPF_AUTO_TARGET_EXE}'"
	elif [[ -n ${OTEL_EBPF_OPEN_PORT:-} ]]; then
		echo "OBI: monitoring processes on ports ${OTEL_EBPF_OPEN_PORT}"
	else
		echo "OBI: monitoring processes on default open ports (80, 443, 8080-8099, 3000-3999, 5000-5999)"
	fi
fi

echo ""
echo "Open ports:"
echo " - 4317: OpenTelemetry GRPC endpoint"
echo " - 4318: OpenTelemetry HTTP endpoint"
echo " - 3000: Grafana (http://localhost:3000). User: admin, password: admin"
echo " - 3200: Tempo endpoint"
echo " - 4040: Pyroscope endpoint"
echo " - 9090: Prometheus endpoint"

# Wait for signal; backgrounded sleep allows the trap to fire
sleep infinity &
wait $!
