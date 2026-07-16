#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	CONFIGDIR="$TESTDIR/etc/lgtm"
	TOKENFILE="$TESTDIR/tmp/grafana-sa-token"
	mkdir -p "$(dirname "$TOKENFILE")"
	cp "$BATS_TEST_DIRNAME/run-all.sh" "$TESTDIR/"

	for script in \
		run-grafana.sh \
		run-loki.sh \
		run-otelcol.sh \
		run-prometheus.sh \
		run-tempo.sh \
		run-pyroscope.sh; do
		cat >"$TESTDIR/$script" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "${STUB_IGNORE_TERM:-false}" == "true" ]]; then
	trap '' TERM
fi
exec sleep 60
SCRIPT
		chmod +x "$TESTDIR/$script"
	done

	cat >"$TESTDIR/curl" <<'SCRIPT'
#!/usr/bin/env bash
args="$*"
mode="${STUB_SA_MODE:-success}"

if [[ "$args" == *"/ready"* ||
	"$args" == *"/api/health"* ||
	"$args" == *"/api/v1/status/runtimeinfo"* ]]; then
	printf '200'
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/1/tokens"* && "$args" == *"-X DELETE"* ]]; then
	printf '{}'
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/1/tokens"* && "$args" == *"-d"* ]]; then
	if [[ "$mode" == "success" || "$mode" == "with_existing_token" ]]; then
		printf '{"key":"token123"}'
	fi
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/1/tokens"* ]]; then
	if [[ "$mode" == "with_existing_token" ]]; then
		printf '[{"id":99,"name":"ai-tools-token"}]'
	else
		printf '[]'
	fi
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/search?query=ai-tools"* ]]; then
	if [[ "$mode" == "lookup_existing" ]]; then
		printf '{"serviceAccounts":[{"id":1,"name":"ai-tools"}]}'
	else
		printf '{}'
	fi
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts"* && "$args" == *"-d"* ]]; then
	if [[ "$mode" == "success" || "$mode" == "with_existing_token" ]]; then
		printf '{"id":1}'
	fi
	exit 0
fi

printf '{}'
SCRIPT
	chmod +x "$TESTDIR/curl"

	# Stub `claude` so executing the generated helper script never invokes a
	# real Claude CLI or mutates the user's own ~/.claude.json.
	cat >"$TESTDIR/claude" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
	chmod +x "$TESTDIR/claude"
}

teardown() {
	rm -rf "$TESTDIR"
}

run_run_all() {
	local version=${1:-latest}
	cd "$TESTDIR" || return 1
	PATH="$TESTDIR:$PATH" \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_VERSION="$version" \
		CONTAINER_RUNTIME=docker \
			timeout 3s bash ./run-all.sh
}

run_run_all_with_stubborn_children() {
	cd "$TESTDIR" || return 1
	PATH="$TESTDIR:$PATH" \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_VERSION=latest \
		CONTAINER_RUNTIME=docker \
		LGTM_SHUTDOWN_TIMEOUT_SECONDS=0.1 \
		STUB_IGNORE_TERM=true \
			timeout --preserve-status --signal=TERM --kill-after=2s 1s bash ./run-all.sh
}

run_mcp_case() {
	local tempo_enabled=$1
	local sa_mode=$2
	local version=${3:-latest}
	if [[ "$tempo_enabled" == "true" ]]; then
		export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	else
		unset TEMPO_EXTRA_ARGS
	fi
	export STUB_SA_MODE="$sa_mode"
	run run_run_all "$version"
}

assert_contains() {
	local needle=$1
	[[ "$output" == *"$needle"* ]]
}

assert_not_contains() {
	local needle=$1
	[[ "$output" != *"$needle"* ]]
}

assert_has_file() {
	[ -f "$1" ]
}

assert_no_file() {
	[ ! -f "$1" ]
}

assert_file_contains() {
	grep -Fq "$2" "$1"
}

assert_file_not_contains() {
	! grep -Fq "$2" "$1"
}

@test "shutdown force stops children after the grace period" {
	run run_run_all_with_stubborn_children
	[ "$status" -eq 0 ]
	assert_contains "Shutting down..."
}

@test "docs URL uses main for latest" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	run run_run_all latest
	assert_contains "  Docs:         $expected"
	assert_not_contains "/blob/vlatest/"
}

@test "docs URL uses main when version is empty" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	run run_run_all ""
	assert_contains "  Docs:         $expected"
}

@test "docs URL uses main for main tag" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	run run_run_all main
	assert_contains "  Docs:         $expected"
	assert_not_contains "/blob/vmain/"
}

@test "printed MCP commands escape configurable paths" {
	local configdir="$TESTDIR/etc/lgtm with spaces"
	local escaped_configdir=${configdir// /\\ }
	CONFIGDIR="$configdir" run run_run_all latest
	assert_contains "bash <(docker exec lgtm cat ${escaped_configdir}/claude-mcp-setup.sh)"
	assert_contains "docker exec lgtm cat ${escaped_configdir}/mcp.json"
}

@test "docs URL prefixes bare release version with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	run run_run_all 1.2.3-test
	assert_contains "  Docs:         $expected"
}

@test "docs URL does not double-prefix version that already starts with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	run run_run_all v1.2.3-test
	assert_contains "  Docs:         $expected"
	assert_not_contains "/blob/vv1.2.3-test/"
}

@test "tempo enabled with service account writes both MCP servers" {
	run_mcp_case true success latest
	assert_contains "Tempo MCP:    server enabled at http://localhost:3200/api/mcp"
	assert_contains "Grafana MCP:  server enabled with service account token"
	assert_contains " - 3200: Tempo endpoint (MCP at http://localhost:3200/api/mcp)"
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_has_file "$TOKENFILE"
	assert_file_contains "$CONFIGDIR/mcp.json" '"grafana"'
	assert_file_contains "$CONFIGDIR/mcp.json" '"tempo"'
	assert_file_contains "$CONFIGDIR/mcp.json" 'GRAFANA_SERVICE_ACCOUNT_TOKEN": "token123"'
	assert_file_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add grafana'
	assert_file_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add --transport http tempo'
	assert_file_contains "$TOKENFILE" 'token123'
}

@test "tempo disabled with service account writes grafana-only MCP config" {
	run_mcp_case false success latest
	assert_contains "Tempo MCP:    server disabled; enable with"
	assert_contains "TEMPO_EXTRA_ARGS=--query-frontend.mcp-server.enabled=true"
	assert_contains "Grafana MCP:  server enabled with service account token"
	assert_contains " - 3200: Tempo endpoint"
	assert_not_contains " - 3200: Tempo endpoint (MCP at http://localhost:3200/api/mcp)"
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_has_file "$TOKENFILE"
	assert_file_contains "$CONFIGDIR/mcp.json" '"grafana"'
	assert_file_not_contains "$CONFIGDIR/mcp.json" '"tempo"'
	assert_file_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add grafana'
	assert_file_not_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add --transport http tempo'
}

@test "tempo enabled without service account writes tempo-only MCP config" {
	run_mcp_case true missing latest
	assert_contains "Tempo MCP:    server enabled at http://localhost:3200/api/mcp"
	assert_contains "Grafana MCP:  server unavailable; could not create service account token"
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_no_file "$TOKENFILE"
	assert_file_not_contains "$CONFIGDIR/mcp.json" '"grafana"'
	assert_file_contains "$CONFIGDIR/mcp.json" '"tempo"'
	assert_file_not_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add grafana'
	assert_file_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add --transport http tempo'
}

@test "tempo disabled without service account writes empty MCP config" {
	run_mcp_case false missing latest
	assert_contains "Tempo MCP:    server disabled; enable with"
	assert_contains "TEMPO_EXTRA_ARGS=--query-frontend.mcp-server.enabled=true"
	assert_contains "Grafana MCP:  server unavailable; could not create service account token"
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_no_file "$TOKENFILE"
	assert_file_contains "$CONFIGDIR/mcp.json" '"mcpServers": {}'
	assert_file_not_contains "$CONFIGDIR/claude-mcp-setup.sh" 'claude mcp add '
}

@test "TEMPO_URL cannot inject commands into generated helper script" {
	local marker="$TESTDIR/injected"
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export STUB_SA_MODE="missing"
	export TEMPO_URL="http://localhost:3200\"; touch ${marker}; echo \""
	run run_run_all latest
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_file_not_contains "$CONFIGDIR/claude-mcp-setup.sh" "; touch ${marker}"
	PATH="$TESTDIR:$PATH" run bash "$CONFIGDIR/claude-mcp-setup.sh"
	[ ! -e "$marker" ]
}

@test "TEMPO_URL cannot inject extra servers into generated mcp.json" {
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export STUB_SA_MODE="missing"
	export TEMPO_URL='http://x"},"evil":{"command":"sh","args":["-c","id"]'
	run run_run_all latest
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_file_not_contains "$CONFIGDIR/mcp.json" '"},"evil"'
	assert_file_contains "$CONFIGDIR/mcp.json" '\"},\"evil\"'
}

@test "GRAFANA_PUBLIC_URL cannot inject commands into generated helper script" {
	local marker="$TESTDIR/injected"
	export STUB_SA_MODE="success"
	export GRAFANA_PUBLIC_URL="http://localhost:3000\"; touch ${marker}; echo \""
	run run_run_all latest
	assert_has_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_file_not_contains "$CONFIGDIR/claude-mcp-setup.sh" "; touch ${marker}"
	PATH="$TESTDIR:$PATH" run bash "$CONFIGDIR/claude-mcp-setup.sh"
	[ ! -e "$marker" ]
}

@test "GRAFANA_PUBLIC_URL cannot inject extra servers into generated mcp.json" {
	export STUB_SA_MODE="success"
	export GRAFANA_PUBLIC_URL='http://x"},"evil":{"command":"sh","args":["-c","id"]'
	run run_run_all latest
	assert_has_file "$CONFIGDIR/mcp.json"
	assert_file_not_contains "$CONFIGDIR/mcp.json" '"},"evil"'
	assert_file_contains "$CONFIGDIR/mcp.json" '\"},\"evil\"'
}
