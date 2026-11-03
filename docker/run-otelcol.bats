#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031  # export in @bats test is intentionally local
bats_require_minimum_version 1.5.0
# Tests for run-otelcol.sh config generation logic.
# The script is run in a temp dir with a stub logging.sh so that
# run_with_logging records its args without exec-ing the real binary.

setup() {
	TESTDIR=$(mktemp -d)

	# Stub logging.sh: record otelcol args to a file instead of exec-ing.
	cat >"$TESTDIR/logging.sh" <<EOF
run_with_logging() {
	shift 2  # skip name and envvar args
	printf '%s\n' "\$@" >"$TESTDIR/otelcol-invocation"
	printf '%s\0' "\$@" >"$TESTDIR/otelcol-invocation-nul"
}
EOF

	cp "$BATS_TEST_DIRNAME/run-otelcol.sh" "$TESTDIR/"
	cp "$BATS_TEST_DIRNAME/common.sh" "$TESTDIR/"

	export OPENTELEMETRY_COLLECTOR_VERSION="test"
	unset OTEL_EXPORTER_OTLP_ENDPOINT \
		OTEL_EXPORTER_OTLP_TRACES_ENDPOINT \
		OTEL_EXPORTER_OTLP_METRICS_ENDPOINT \
		OTEL_EXPORTER_OTLP_LOGS_ENDPOINT \
		OTEL_EXPORTER_OTLP_HEADERS \
		OTEL_COLLECTOR_DEBUG_EXPORTER \
		OTELCOL_EXTRA_ARGS 2>/dev/null || true
}

teardown() {
	rm -rf "$TESTDIR"
}

run_otelcol() {
	cd "$TESTDIR" && bash run-otelcol.sh "$@"
}

# --- no flags ---

@test "no flags: no overlay config generated" {
	run run_otelcol
	[ "$status" -eq 0 ]
	[ ! -f "$TESTDIR/otelcol-config-export-http.yaml" ]
}

@test "no flags: otelcol started with only base config" {
	run run_otelcol
	[ "$status" -eq 0 ]
	grep -q -- "--config=file:./otelcol-config.yaml" "$TESTDIR/otelcol-invocation"
	run ! grep -q "otelcol-config-export-http" "$TESTDIR/otelcol-invocation"
	mapfile -d '' -t args <"$TESTDIR/otelcol-invocation-nul"
	[ "${#args[@]}" -eq 4 ]
	[ "${args[0]}" = "./otelcol-contrib/otelcol-contrib" ]
	[ "${args[1]}" = "--feature-gates" ]
	[ "${args[2]}" = "service.profilesSupport" ]
	[ "${args[3]}" = "--config=file:./otelcol-config.yaml" ]
}

@test "container args: prefixed options are stripped and appended after env args" {
	export OTELCOL_EXTRA_ARGS="--existing=one"
	run run_otelcol --otelcol-feature-gates=first --otelcol-feature-gates=second
	[ "$status" -eq 0 ]
	mapfile -d '' -t args <"$TESTDIR/otelcol-invocation-nul"
	[ "${args[4]}" = "--existing=one" ]
	[ "${args[5]}" = "--feature-gates=first" ]
	[ "${args[6]}" = "--feature-gates=second" ]
	[ "${#args[@]}" -eq 7 ]
}

@test "container args: spaces and newlines stay within one argument" {
	local value=$'first line\nsecond line with spaces'
	run run_otelcol "--otelcol-config=${value}"
	[ "$status" -eq 0 ]
	mapfile -d '' -t args <"$TESTDIR/otelcol-invocation-nul"
	[ "${args[4]}" = "--config=${value}" ]
	[ "${#args[@]}" -eq 5 ]
}

@test "container args: non-prefixed and bare-prefix args are ignored" {
	run run_otelcol --unrelated-flag --otelcol- --otelcol-name=value
	[ "$status" -eq 0 ]
	mapfile -d '' -t args <"$TESTDIR/otelcol-invocation-nul"
	[ "${args[4]}" = "--name=value" ]
	[ "${#args[@]}" -eq 5 ]
}

# --- debug only ---

@test "debug only: overlay generated" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	run run_otelcol
	[ "$status" -eq 0 ]
	[ -f "$TESTDIR/otelcol-config-export-http.yaml" ]
}

@test "debug only: overlay has debug exporters for all signals" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	run run_otelcol
	grep -q "debug/traces" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "debug/metrics" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "debug/logs" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "debug only: overlay has no external exporters" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	run run_otelcol
	run ! grep -q "otlp_http/external" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "debug only: overlay passed to otelcol" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	run run_otelcol
	grep -q "otelcol-config-export-http" "$TESTDIR/otelcol-invocation"
}

# --- external only (shared endpoint) ---

@test "external only: overlay has external exporters for all signals" {
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	run run_otelcol
	grep -q "otlp_http/external-traces" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "otlp_http/external-metrics" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "otlp_http/external-logs" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "external only: overlay has no debug exporters" {
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	run run_otelcol
	run ! grep -q "debug/" "$TESTDIR/otelcol-config-export-http.yaml"
}

# --- per-signal external endpoints ---

@test "per-signal: only configured signals get external exporter" {
	export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://tempo:4318
	run run_otelcol
	grep -q "otlp_http/external-traces" "$TESTDIR/otelcol-config-export-http.yaml"
	run ! grep -q "otlp_http/external-metrics" "$TESTDIR/otelcol-config-export-http.yaml"
	run ! grep -q "otlp_http/external-logs" "$TESTDIR/otelcol-config-export-http.yaml"
}

# --- both debug and external ---

@test "both: overlay has debug and external exporters for all signals" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	run run_otelcol
	grep -q "debug/traces" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "debug/metrics" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "debug/logs" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "otlp_http/external-traces" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "otlp_http/external-metrics" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "otlp_http/external-logs" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "both: only one overlay config passed to otelcol" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	run run_otelcol
	count=$(grep -c "otelcol-config-export-http" "$TESTDIR/otelcol-invocation")
	[ "$count" -eq 1 ]
}

# --- headers ---

@test "headers: added to external endpoints in overlay" {
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer token123"
	run run_otelcol
	grep -q "headers:" "$TESTDIR/otelcol-config-export-http.yaml"
	grep -q "Authorization" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "headers: not applied when debug only (no external endpoints)" {
	export OTEL_COLLECTOR_DEBUG_EXPORTER=true
	export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer token123"
	run run_otelcol
	run ! grep -q "headers:" "$TESTDIR/otelcol-config-export-http.yaml"
}

@test "headers: value containing = (e.g. padded base64) is preserved intact" {
	local b64="ZmFrZS1pbnN0YW5jZS1pZDpmYWtlLXRva2VuLXZhbHVlPT0="
	export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
	export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic ${b64}"
	run run_otelcol
	grep -q "Basic ${b64}" "$TESTDIR/otelcol-config-export-http.yaml"
}
