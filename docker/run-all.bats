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
sleep 60
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

@test "docs URL uses main for latest" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all latest
	[[ "$output" == *"$expected_line"* ]]
	[[ "$output" != *"/blob/vlatest/"* ]]
}

@test "docs URL uses main when version is empty" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all ""
	[[ "$output" == *"$expected_line"* ]]
}

@test "docs URL uses main for main tag" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all main
	[[ "$output" == *"$expected_line"* ]]
	[[ "$output" != *"/blob/vmain/"* ]]
}

@test "printed MCP commands escape configurable paths" {
	local configdir="$TESTDIR/etc/lgtm with spaces"
	local escaped_configdir=${configdir// /\\ }
	CONFIGDIR="$configdir" run run_run_all latest
	[[ "$output" == *"bash <(docker exec lgtm cat ${escaped_configdir}/claude-mcp-setup.sh)"* ]]
	[[ "$output" == *"docker exec lgtm cat ${escaped_configdir}/mcp.json"* ]]
}

@test "docs URL prefixes bare release version with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all 1.2.3-test
	[[ "$output" == *"$expected_line"* ]]
}

@test "docs URL does not double-prefix version that already starts with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all v1.2.3-test
	[[ "$output" == *"$expected_line"* ]]
	[[ "$output" != *"/blob/vv1.2.3-test/"* ]]
}

@test "MCP bootstrap writes helper artifacts with expected contents" {
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export STUB_SA_MODE=success

	run run_run_all latest
	[ -f "$CONFIGDIR/mcp.json" ]
	[ -f "$CONFIGDIR/claude-mcp-setup.sh" ]
	[ -f "$TOKENFILE" ]

	grep -Fq \
		'"GRAFANA_URL": "http://localhost:3000"' \
		"$CONFIGDIR/mcp.json"
	grep -Fq \
		'"GRAFANA_SERVICE_ACCOUNT_TOKEN": "token123"' \
		"$CONFIGDIR/mcp.json"
	grep -Fq '"url": "http://localhost:3200/api/mcp"' "$CONFIGDIR/mcp.json"

	grep -Fq \
		'claude mcp add grafana -e "GRAFANA_URL=http://localhost:3000"' \
		"$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fq 'GRAFANA_SERVICE_ACCOUNT_TOKEN=token123' "$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fq \
		'claude mcp add --transport http tempo "http://localhost:3200/api/mcp"' \
		"$CONFIGDIR/claude-mcp-setup.sh"

	grep -Fqx 'token123' "$TOKENFILE"
}

@test "enabled tempo with service account writes both MCP servers" {
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export STUB_SA_MODE=success

	run run_run_all latest
	[[ "$output" == *"Tempo MCP:    server enabled at http://localhost:3200/api/mcp"* ]]
	[[ "$output" == *"Grafana MCP:  server enabled with service account token"* ]]
	[[ "$output" == *" - 3200: Tempo endpoint (MCP at http://localhost:3200/api/mcp)"* ]]

	grep -Fq '"grafana"' "$CONFIGDIR/mcp.json"
	grep -Fq '"tempo"' "$CONFIGDIR/mcp.json"
	grep -Fq 'GRAFANA_SERVICE_ACCOUNT_TOKEN": "token123"' "$CONFIGDIR/mcp.json"
	grep -Fq 'claude mcp add grafana' "$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fq \
		'claude mcp add --transport http tempo "http://localhost:3200/api/mcp"' \
		"$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fqx 'token123' "$TOKENFILE"
}

@test "disabled tempo with service account writes grafana-only MCP config" {
	unset TEMPO_EXTRA_ARGS
	export STUB_SA_MODE=success

	run run_run_all latest
	[[ "$output" == *"Tempo MCP:    server disabled;"* ]]
	[[ "$output" == *"TEMPO_EXTRA_ARGS=--query-frontend.mcp-server.enabled=true"* ]]
	[[ "$output" == *"Grafana MCP:  server enabled with service account token"* ]]
	[[ "$output" == *" - 3200: Tempo endpoint"* ]]
	[[ "$output" != *" - 3200: Tempo endpoint (MCP at http://localhost:3200/api/mcp)"* ]]

	grep -Fq '"grafana"' "$CONFIGDIR/mcp.json"
	run ! grep -Fq '"tempo"' "$CONFIGDIR/mcp.json"
	grep -Fq 'claude mcp add grafana' "$CONFIGDIR/claude-mcp-setup.sh"
	run ! grep -Fq 'claude mcp add --transport http tempo' "$CONFIGDIR/claude-mcp-setup.sh"
}

@test "enabled tempo without service account writes tempo-only MCP config" {
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export STUB_SA_MODE=missing

	run run_run_all latest
	[[ "$output" == *"Tempo MCP:    server enabled at http://localhost:3200/api/mcp"* ]]
	[[ "$output" == *"Grafana MCP:  server unavailable; could not create service account token"* ]]

	run ! grep -Fq '"grafana"' "$CONFIGDIR/mcp.json"
	grep -Fq '"tempo"' "$CONFIGDIR/mcp.json"
	run ! grep -Fq 'claude mcp add grafana' "$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fq \
		'claude mcp add --transport http tempo "http://localhost:3200/api/mcp"' \
		"$CONFIGDIR/claude-mcp-setup.sh"
	[ ! -f "$TOKENFILE" ]
}

@test "disabled tempo without service account writes empty MCP config" {
	unset TEMPO_EXTRA_ARGS
	export STUB_SA_MODE=missing

	run run_run_all latest
	[[ "$output" == *"Tempo MCP:    server disabled;"* ]]
	[[ "$output" == *"TEMPO_EXTRA_ARGS=--query-frontend.mcp-server.enabled=true"* ]]
	[[ "$output" == *"Grafana MCP:  server unavailable; could not create service account token"* ]]

	grep -Fq '"mcpServers": {}' "$CONFIGDIR/mcp.json"
	run ! grep -Fq 'claude mcp add ' "$CONFIGDIR/claude-mcp-setup.sh"
	[ ! -f "$TOKENFILE" ]
}
