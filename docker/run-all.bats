#!/usr/bin/env bats
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
		cat >"$TESTDIR/$script" <<'EOF'
#!/usr/bin/env bash
sleep 60
EOF
		chmod +x "$TESTDIR/$script"
	done

	cat >"$TESTDIR/curl" <<'EOF'
#!/usr/bin/env bash
args="$*"

if [[ "$args" == *"/ready"* ||
	"$args" == *"/api/health"* ||
	"$args" == *"/api/v1/status/runtimeinfo"* ]]; then
	printf '200'
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/1/tokens"* && "$args" == *"-d"* ]]; then
	printf '{"key":"token123"}'
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts/1/tokens"* ]]; then
	printf '[]'
	exit 0
fi

if [[ "$args" == *"/api/serviceaccounts"* && "$args" == *"-d"* ]]; then
	printf '{"id":1}'
	exit 0
fi

printf '{}'
EOF
	chmod +x "$TESTDIR/curl"
}

teardown() {
	rm -rf "$TESTDIR"
}

run_run_all() {
	local version=$1
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
	run run_run_all "latest"
	[[ "$output" == *"$expected_line"* ]]
	[[ "$output" != *"/blob/vlatest/"* ]]
}

@test "docs URL uses main when version is empty" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all ""
	[[ "$output" == *"$expected_line"* ]]
}

@test "docs URL prefixes bare release version with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all "1.2.3-test"
	[[ "$output" == *"$expected_line"* ]]
}

@test "docs URL does not double-prefix version that already starts with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/mcp-integration.md"
	local expected_line="  Docs:         $expected"
	run run_run_all "v1.2.3-test"
	[[ "$output" == *"$expected_line"* ]]
	[[ "$output" != *"/blob/vv1.2.3-test/"* ]]
}

@test "MCP bootstrap writes helper artifacts with expected contents" {
	run run_run_all "latest"
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
	grep -Fq \
		'GRAFANA_SERVICE_ACCOUNT_TOKEN=token123' \
		"$CONFIGDIR/claude-mcp-setup.sh"
	grep -Fq \
		'claude mcp add --transport http tempo "http://localhost:3200/api/mcp"' \
		"$CONFIGDIR/claude-mcp-setup.sh"

	grep -Fqx 'token123' "$TOKENFILE"
}
