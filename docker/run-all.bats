#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	CONFIGDIR="$TESTDIR/etc/lgtm"
	TOKENFILE="$TESTDIR/tmp/grafana-sa-token"
	READY_FILE="$TESTDIR/tmp/ready"
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
service=${0##*/run-}
service=${service%.sh}
if [[ -n ${STUB_CHILD_PIDS_DIR:-} ]]; then
	echo "$$" >"$STUB_CHILD_PIDS_DIR/$service"
fi
if [[ "$0" == *run-otelcol.sh ]]; then
	: >"$STUB_OTELCOL_ARGS"
	if (($#)); then printf '%s\0' "$@" >"$STUB_OTELCOL_ARGS"; fi
fi
if [[ "${STUB_IGNORE_TERM:-false}" == "true" ]]; then
	trap '' TERM
fi
if [[ ${STUB_EXIT_SERVICE:-} == "$service" ]]; then
	while [[ ! -e ${STUB_EXIT_TRIGGER:?} ]]; do sleep 0.05; done
	exit "${STUB_EXIT_STATUS:-1}"
fi
exec sleep 60
SCRIPT
		chmod +x "$TESTDIR/$script"
	done

	cat >"$TESTDIR/curl" <<'SCRIPT'
#!/usr/bin/env bash
args="$*"
printf '%s\n' "$args" >>"${STUB_CURL_LOG:?}"

if [[ "$args" == *"/ready"* ||
	"$args" == *"/api/health"* ||
	"$args" == *"/api/v1/status/runtimeinfo"* ]]; then
	if [[ "${STUB_STACK_NOT_READY:-false}" == "true" ]]; then
		printf '000'
		exit 0
	fi
	printf '200'
	exit 0
fi

echo "Unexpected startup HTTP request" >&2
exit 1
SCRIPT
	chmod +x "$TESTDIR/curl"

}

run_run_all_with_post_readiness_exit() {
	local service=$1
	local exit_status=$2
	cd "$TESTDIR" || return 1
	rm -f "$READY_FILE" "$TESTDIR/exit-now" "$TESTDIR/run-all-output"
	rm -rf "$TESTDIR/child-pids"
	mkdir -p "$TESTDIR/child-pids"
	PATH="$TESTDIR:$PATH" \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_READY_FILE="$READY_FILE" \
		LGTM_VERSION=latest \
		STUB_CURL_LOG="$TESTDIR/curl-calls" \
		STUB_OTELCOL_ARGS="$TESTDIR/otelcol-args" \
		STUB_CHILD_PIDS_DIR="$TESTDIR/child-pids" \
		STUB_EXIT_SERVICE="$service" \
		STUB_EXIT_STATUS="$exit_status" \
		STUB_EXIT_TRIGGER="$TESTDIR/exit-now" \
		timeout --preserve-status --signal=TERM --kill-after=2s 10s \
		bash ./run-all.sh >"$TESTDIR/run-all-output" 2>&1 &
	local launcher_pid=$!
	local attempt
	for ((attempt = 0; attempt < 100; attempt++)); do
		[[ -f "$READY_FILE" ]] && break
		sleep 0.05
	done
	if [[ ! -f "$READY_FILE" ]]; then
		kill "$launcher_pid" 2>/dev/null || true
		wait "$launcher_pid" 2>/dev/null || true
		cat "$TESTDIR/run-all-output"
		return 1
	fi
	touch "$TESTDIR/exit-now"
	local status=0
	wait "$launcher_pid" || status=$?
	cat "$TESTDIR/run-all-output"
	return "$status"
}

run_run_all_with_optional_obi_exit() {
	cd "$TESTDIR" || return 1
	rm -f "$READY_FILE" "$TESTDIR/exit-now" "$TESTDIR/run-all-output"
	cat >"$TESTDIR/run-obi.sh" <<'SCRIPT'
#!/usr/bin/env bash
while [[ ! -e ${STUB_EXIT_TRIGGER:?} ]]; do sleep 0.05; done
exit 1
SCRIPT
	chmod +x "$TESTDIR/run-obi.sh"
	PATH="$TESTDIR:$PATH" \
		ENABLE_OBI=true \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_READY_FILE="$READY_FILE" \
		LGTM_VERSION=latest \
		STUB_CURL_LOG="$TESTDIR/curl-calls" \
		STUB_OTELCOL_ARGS="$TESTDIR/otelcol-args" \
		STUB_EXIT_TRIGGER="$TESTDIR/exit-now" \
		timeout --preserve-status --signal=TERM --kill-after=2s 10s \
		bash ./run-all.sh >"$TESTDIR/run-all-output" 2>&1 &
	local launcher_pid=$!
	local attempt
	for ((attempt = 0; attempt < 100; attempt++)); do
		[[ -f "$READY_FILE" ]] && break
		sleep 0.05
	done
	if [[ ! -f "$READY_FILE" ]]; then
		kill "$launcher_pid" 2>/dev/null || true
		wait "$launcher_pid" 2>/dev/null || true
		cat "$TESTDIR/run-all-output"
		return 1
	fi
	touch "$TESTDIR/exit-now"
	sleep 1.2
	if ! kill -0 "$launcher_pid" 2>/dev/null || [[ ! -f "$READY_FILE" ]]; then
		kill -TERM "$launcher_pid" 2>/dev/null || true
		wait "$launcher_pid" 2>/dev/null || true
		cat "$TESTDIR/run-all-output"
		return 1
	fi
	kill -TERM "$launcher_pid"
	local status=0
	wait "$launcher_pid" || status=$?
	cat "$TESTDIR/run-all-output"
	return "$status"
}

teardown() {
	rm -rf "$TESTDIR"
}

run_run_all() {
	local version=${1-latest}
	shift || true
	cd "$TESTDIR" || return 1
	PATH="$TESTDIR:$PATH" \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_READY_FILE="$READY_FILE" \
		LGTM_VERSION="$version" \
		STUB_CURL_LOG="$TESTDIR/curl-calls" \
		STUB_OTELCOL_ARGS="$TESTDIR/otelcol-args" \
		timeout 3s bash ./run-all.sh "$@"
}

@test "clears a stale readiness marker before restarting services" {
	touch "$READY_FILE"

	STUB_STACK_NOT_READY=true run run_run_all

	[ "$status" -eq 124 ]
	assert_no_file "$READY_FILE"
	[ ! -s "$TESTDIR/otelcol-args" ]
}

@test "forwards only prefixed collector args in order without changing boundaries" {
	local multiline=$'first line\nsecond line with spaces'
	run run_run_all latest --other-flag \
		"--otelcol-config=${multiline}" \
		--otelcol-feature-gates=one \
		--otelcol-feature-gates=two \
		--otelcol-
	[ "$status" -eq 124 ]
	mapfile -d '' -t args <"$TESTDIR/otelcol-args"
	[ "${#args[@]}" -eq 4 ]
	[ "${args[0]}" = "--otelcol-config=${multiline}" ]
	[ "${args[1]}" = "--otelcol-feature-gates=one" ]
	[ "${args[2]}" = "--otelcol-feature-gates=two" ]
	[ "${args[3]}" = "--otelcol-" ]
}

@test "forwards no args when container args are unprefixed" {
	run run_run_all latest --other-flag
	[ "$status" -eq 124 ]
	[ ! -s "$TESTDIR/otelcol-args" ]
}

run_run_all_with_stubborn_children() {
	cd "$TESTDIR" || return 1
	PATH="$TESTDIR:$PATH" \
		LGTM_CONFIG_DIR="$CONFIGDIR" \
		GRAFANA_SA_TOKEN_FILE="$TOKENFILE" \
		LGTM_READY_FILE="$READY_FILE" \
		LGTM_VERSION=latest \
		STUB_CURL_LOG="$TESTDIR/curl-calls" \
		STUB_OTELCOL_ARGS="$TESTDIR/otelcol-args" \
		LGTM_SHUTDOWN_TIMEOUT_SECONDS=0.1 \
		STUB_IGNORE_TERM=true \
		timeout --preserve-status --signal=TERM --kill-after=2s 1s bash ./run-all.sh
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

assert_process_stopped() {
	! kill -0 "$1" 2>/dev/null
}

@test "shutdown force stops children after the grace period" {
	run run_run_all_with_stubborn_children
	[ "$status" -eq 0 ]
	assert_contains "Shutting down..."
}

@test "fails fast when a component exits before becoming ready" {
	cat >"$TESTDIR/run-loki.sh" <<'SCRIPT'
#!/usr/bin/env bash
exit 1
SCRIPT
	chmod +x "$TESTDIR/run-loki.sh"

	# A well-behaved component that should be stopped (not orphaned) once
	# the startup failure is detected. It records its own PID, then execs
	# (like the real wrapper scripts) so a bash trap wouldn't fire anyway -
	# the check below relies on the process itself no longer existing.
	local pidfile="$TESTDIR/grafana.pid"
	cat >"$TESTDIR/run-grafana.sh" <<SCRIPT
#!/usr/bin/env bash
echo \$\$ >"${pidfile}"
exec sleep 60
SCRIPT
	chmod +x "$TESTDIR/run-grafana.sh"

	cat >"$TESTDIR/curl" <<'SCRIPT'
#!/usr/bin/env bash
args="$*"

if [[ "$args" == *"127.0.0.1:3100/ready"* ]]; then
	printf '000'
	exit 0
fi

if [[ "$args" == *"/ready"* ||
	"$args" == *"/api/health"* ||
	"$args" == *"/api/v1/status/runtimeinfo"* ]]; then
	printf '200'
	exit 0
fi

printf '{}'
SCRIPT
	chmod +x "$TESTDIR/curl"

	run run_run_all
	[ "$status" -eq 1 ]
	assert_contains "Error: Loki exited before becoming ready."
	assert_contains "Re-run with ENABLE_LOGS_LOKI=true (or ENABLE_LOGS_ALL=true) to see its output."
	assert_has_file "$pidfile"
	assert_process_stopped "$(cat "$pidfile")"
}

@test "fails the container when a required component exits after readiness" {
	for service in grafana loki otelcol prometheus tempo pyroscope; do
		run run_run_all_with_post_readiness_exit "$service" 1
		[ "$status" -eq 1 ]
		assert_contains "Error: ${service^} exited after becoming ready with status 1."
		local log_hint="Re-run with ENABLE_LOGS_${service^^}=true "
		log_hint+="(or ENABLE_LOGS_ALL=true) to see its output."
		assert_contains "$log_hint"
		assert_no_file "$READY_FILE"
		for child in grafana loki otelcol prometheus tempo pyroscope; do
			assert_process_stopped "$(cat "$TESTDIR/child-pids/$child")"
		done
	done
}

@test "fails the container when a required component exits successfully after readiness" {
	run run_run_all_with_post_readiness_exit loki 0
	[ "$status" -eq 1 ]
	assert_contains "Error: Loki exited after becoming ready with status 0."
	assert_no_file "$READY_FILE"
	for service in grafana otelcol prometheus tempo pyroscope; do
		assert_process_stopped "$(cat "$TESTDIR/child-pids/$service")"
	done
}

@test "an optional OBI exit does not stop the stack" {
	run run_run_all_with_optional_obi_exit
	[ "$status" -eq 0 ]
	assert_has_file "$READY_FILE"
}

@test "docs URL uses main for latest" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/gcx-integration.md"
	run run_run_all latest
	assert_contains "  $expected"
	assert_not_contains "/blob/vlatest/"
}

@test "docs URL uses main when version is empty" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/gcx-integration.md"
	run run_run_all ""
	assert_contains "  $expected"
}

@test "docs URL uses main for main tag" {
	local expected="https://github.com/grafana/docker-otel-lgtm/blob/main/docs/gcx-integration.md"
	run run_run_all main
	assert_contains "  $expected"
	assert_not_contains "/blob/vmain/"
}

@test "docs URL prefixes bare release version with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/gcx-integration.md"
	run run_run_all 1.2.3-test
	assert_contains "  $expected"
}

@test "docs URL does not double-prefix version that already starts with v" {
	local expected
	expected="https://github.com/grafana/docker-otel-lgtm/blob/v1.2.3-test/docs/gcx-integration.md"
	run run_run_all v1.2.3-test
	assert_contains "  $expected"
	assert_not_contains "/blob/vv1.2.3-test/"
}

@test "docs URL uses main for development refs" {
	run run_run_all gcx-entry
	assert_contains "  https://github.com/grafana/docker-otel-lgtm/blob/main/docs/gcx-integration.md"
	assert_not_contains "/blob/vgcx-entry/"
}

@test "prints one local gcx guide after readiness without MCP promotion" {
	run run_run_all latest
	[ "$status" -eq 124 ]
	assert_has_file "$READY_FILE"
	assert_contains "Query and troubleshoot telemetry with gcx:"
	[ "$(printf '%s\n' "$output" | grep -Fc 'Query and troubleshoot telemetry with gcx:')" -eq 1 ]
	[ "$(printf '%s\n' "$output" | grep -Fc '/docs/gcx-integration.md')" -eq 1 ]
	local ready_line guide_line
	ready_line=$(printf '%s\n' "$output" | grep -n 'created .*ready)' | cut -d: -f1)
	guide_line=$(printf '%s\n' "$output" | grep -n 'Query and troubleshoot' | cut -d: -f1)
	[ "$ready_line" -lt "$guide_line" ]
	assert_not_contains "MCP"
	assert_not_contains "claude-mcp-setup.sh"
	assert_contains " - 3200: Tempo endpoint"
}

@test "does not bootstrap credentials or write generated client files" {
	run run_run_all latest
	[ "$status" -eq 124 ]
	assert_no_file "$TOKENFILE"
	assert_no_file "$CONFIGDIR/mcp.json"
	assert_no_file "$CONFIGDIR/claude-mcp-setup.sh"
	[ ! -d "$CONFIGDIR" ]
	[ "$(wc -l <"$TESTDIR/curl-calls")" -eq 6 ]
	[ "$(grep -Fc '/api/serviceaccounts' "$TESTDIR/curl-calls" || true)" -eq 0 ]
}

@test "leaves pre-existing generated files and tokens untouched" {
	mkdir -p "$CONFIGDIR"
	printf 'existing config' >"$CONFIGDIR/mcp.json"
	printf 'existing script' >"$CONFIGDIR/claude-mcp-setup.sh"
	printf 'existing token' >"$TOKENFILE"
	run run_run_all latest
	[ "$status" -eq 124 ]
	[ "$(cat "$CONFIGDIR/mcp.json")" = 'existing config' ]
	[ "$(cat "$CONFIGDIR/claude-mcp-setup.sh")" = 'existing script' ]
	[ "$(cat "$TOKENFILE")" = 'existing token' ]
	[ "$(grep -Fc '/api/serviceaccounts' "$TESTDIR/curl-calls" || true)" -eq 0 ]
	assert_not_contains "existing token"
}

@test "legacy MCP options neither execute nor appear in the gcx message" {
	local marker="$TESTDIR/injected"
	export TEMPO_EXTRA_ARGS="--query-frontend.mcp-server.enabled=true"
	export GRAFANA_PUBLIC_URL="http://localhost:3000\"; touch ${marker}; echo \""
	export TEMPO_URL="$GRAFANA_PUBLIC_URL"
	export GF_SECURITY_ADMIN_PASSWORD="custom-secret-do-not-print"
	run run_run_all latest
	[ "$status" -eq 124 ]
	assert_no_file "$marker"
	assert_no_file "$CONFIGDIR/claude-mcp-setup.sh"
	assert_not_contains "MCP"
	assert_not_contains "custom-secret-do-not-print"
	assert_not_contains "$GRAFANA_PUBLIC_URL"
	[ "$(wc -l <"$TESTDIR/curl-calls")" -eq 6 ]
}
