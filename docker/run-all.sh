#!/bin/bash

echo "Starting grafana/otel-lgtm ${LGTM_VERSION}"

# Graceful shutdown: forward SIGTERM/SIGINT to all background jobs
shutdown() {
	echo "Shutting down..."
	# Send SIGTERM to all background jobs (the wrapper scripts exec the
	# server process, so these PIDs are the actual server processes)
	jobs -p | xargs -r kill 2>/dev/null
	wait
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

start_component "pyroscope"
./run-pyroscope.sh &

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

# Wait for all services to be ready
all_ready=false
while [[ $all_ready == false ]]; do
	# Check each service
	for service in "${!services[@]}"; do
		check_service_ready "$service" "${services[$service]}"
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

touch /tmp/ready
echo "The OpenTelemetry collector and the Grafana LGTM stack are up and running. (created /tmp/ready)"

# Create a service account token and MCP config for AI tool access
GRAFANA_CREDS="admin:admin"
GRAFANA_URL="http://127.0.0.1:3000"
# Try to create SA; if it already exists (persisted data), look it up
SA_RESPONSE=$(curl -sf "${GRAFANA_URL}/api/serviceaccounts" \
	-H "Content-Type: application/json" -u "${GRAFANA_CREDS}" \
	-d '{"name":"ai-tools","role":"Viewer"}')
if [ -z "$SA_RESPONSE" ]; then
	# SA already exists — find its ID
	SA_RESPONSE=$(curl -sf "${GRAFANA_URL}/api/serviceaccounts/search?query=ai-tools" -u "${GRAFANA_CREDS}")
	SA_ID=$(echo "$SA_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
else
	SA_ID=$(echo "$SA_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
fi
if [ -n "$SA_ID" ]; then
	# Delete only the bootstrap-managed token (preserve any manually-created tokens)
	EXISTING_TOKENS=$(curl -sf "${GRAFANA_URL}/api/serviceaccounts/${SA_ID}/tokens" -u "${GRAFANA_CREDS}")
	if [ -n "$EXISTING_TOKENS" ]; then
		BOOTSTRAP_TOKEN_ID=$(echo "$EXISTING_TOKENS" | tr '{}' '\n' | grep '"name":"ai-tools-token"' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
		if [ -n "$BOOTSTRAP_TOKEN_ID" ]; then
			curl -sf -X DELETE "${GRAFANA_URL}/api/serviceaccounts/${SA_ID}/tokens/${BOOTSTRAP_TOKEN_ID}" \
				-u "${GRAFANA_CREDS}" >/dev/null
		fi
	fi
	TOKEN_RESPONSE=$(curl -sf "${GRAFANA_URL}/api/serviceaccounts/${SA_ID}/tokens" \
		-H "Content-Type: application/json" -u "${GRAFANA_CREDS}" \
		-d '{"name":"ai-tools-token"}')
	SA_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
	if [ -n "$SA_TOKEN" ]; then
		mkdir -p /etc/lgtm
		EXEC="${CONTAINER_RUNTIME:-docker} exec lgtm"
		(
			umask 077
			echo "${SA_TOKEN}" >/tmp/grafana-sa-token
			cat >/etc/lgtm/mcp.json <<-MCPEOF
				{
				  "mcpServers": {
				    "grafana": {
				      "command": "uvx",
				      "args": ["mcp-grafana"],
				      "env": {
				        "GRAFANA_URL": "http://localhost:3000",
				        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${SA_TOKEN}"
				      }
				    },
				    "tempo": {
				      "url": "http://localhost:3200/api/mcp"
				    }
				  }
				}
			MCPEOF
			cat >/etc/lgtm/claude-mcp-setup.sh <<-SETUPEOF
				#!/bin/bash
				# Connect Claude Code to the LGTM stack
				claude mcp add grafana -e GRAFANA_URL=http://localhost:3000 -e GRAFANA_SERVICE_ACCOUNT_TOKEN="${SA_TOKEN}" -- uvx mcp-grafana
				claude mcp add --transport http tempo http://localhost:3200/api/mcp
			SETUPEOF
		)
		echo ""
		echo "AI Tool Integration (MCP):"
		echo "  Claude Code:  bash <($EXEC cat /etc/lgtm/claude-mcp-setup.sh)"
		echo "  Other tools:  $EXEC cat /etc/lgtm/mcp.json"
		echo "  Docs:         https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	fi
fi

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

echo "Open ports:"
echo " - 4317: OpenTelemetry GRPC endpoint"
echo " - 4318: OpenTelemetry HTTP endpoint"
echo " - 3000: Grafana (http://localhost:3000). User: admin, password: admin"
echo " - 3200: Tempo endpoint (MCP at http://localhost:3200/api/mcp)"
echo " - 4040: Pyroscope endpoint"
echo " - 9090: Prometheus endpoint"

# Wait for signal; backgrounded sleep allows the trap to fire
sleep infinity &
wait $!
