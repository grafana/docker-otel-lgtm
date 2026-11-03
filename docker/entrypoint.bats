#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	RUN_ALL="$TESTDIR/run-all.sh"
	ENTRYPOINT="$TESTDIR/entrypoint.sh"
	cat >"$RUN_ALL" <<'SCRIPT'
#!/usr/bin/env bash
: >"$ENTRYPOINT_ARGS"
if (($#)); then printf '%s\0' "$@" >"$ENTRYPOINT_ARGS"; fi
SCRIPT
	chmod +x "$RUN_ALL"
	sed "s|/otel-lgtm/run-all.sh|$RUN_ALL|g" "$BATS_TEST_DIRNAME/entrypoint.sh" >"$ENTRYPOINT"
	chmod +x "$ENTRYPOINT"
	ENTRYPOINT_ARGS="$TESTDIR/args"
	export ENTRYPOINT_ARGS
}

teardown() {
	rm -rf "$TESTDIR"
}

@test "starts the default services when invoked without arguments" {
	run "$ENTRYPOINT"
	[ "$status" -eq 0 ]
	[ -f "$ENTRYPOINT_ARGS" ]
	[ ! -s "$ENTRYPOINT_ARGS" ]
}

@test "forwards namespaced collector arguments preserving each value" {
	local multiline=$'first line\nsecond line with spaces'
	run "$ENTRYPOINT" --otelcol-config="$multiline" \
		--otelcol-feature-gates=one --otelcol-feature-gates=two
	[ "$status" -eq 0 ]
	mapfile -d '' -t args <"$ENTRYPOINT_ARGS"
	[ "${#args[@]}" -eq 3 ]
	[ "${args[0]}" = "--otelcol-config=$multiline" ]
	[ "${args[1]}" = "--otelcol-feature-gates=one" ]
	[ "${args[2]}" = "--otelcol-feature-gates=two" ]
}

@test "runs a custom command instead of starting the services" {
	cat >"$TESTDIR/command" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\0' "$@" >"$CUSTOM_ARGS"
SCRIPT
	chmod +x "$TESTDIR/command"
	CUSTOM_ARGS="$TESTDIR/custom-args" "$ENTRYPOINT" "$TESTDIR/command" \
		'arg with spaces' $'line one\nline two' --otelcol-custom
	mapfile -d '' -t args <"$TESTDIR/custom-args"
	[ "${#args[@]}" -eq 3 ]
	[ "${args[0]}" = 'arg with spaces' ]
	[ "${args[1]}" = $'line one\nline two' ]
	[ "${args[2]}" = '--otelcol-custom' ]
}

@test "passes an explicit launcher command through unchanged" {
	run "$ENTRYPOINT" /bin/sh -c 'printf shell'
	[ "$status" -eq 0 ]
	[ "$output" = shell ]
}

@test "passes the image's default CMD through to the launcher" {
	run "$ENTRYPOINT" "$RUN_ALL"
	[ "$status" -eq 0 ]
	[ -f "$ENTRYPOINT_ARGS" ]
	[ ! -s "$ENTRYPOINT_ARGS" ]
}

@test "propagates custom command exit status" {
	cat >"$TESTDIR/failing-command" <<'SCRIPT'
#!/usr/bin/env bash
exit 42
SCRIPT
	chmod +x "$TESTDIR/failing-command"
	run "$ENTRYPOINT" "$TESTDIR/failing-command"
	[ "$status" -eq 42 ]
}
