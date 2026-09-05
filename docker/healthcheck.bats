#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	READY_FILE="$TESTDIR/ready"
	CURL_LOG="$TESTDIR/curl.log"

	sed "s#/tmp/ready#$READY_FILE#" "$BATS_TEST_DIRNAME/healthcheck.sh" >"$TESTDIR/healthcheck.sh"
	cat >"$TESTDIR/curl" <<'SCRIPT'
#!/usr/bin/env bash
fail_on_http=false
for arg in "$@"; do
	case "$arg" in
	-*f*) fail_on_http=true ;;
	esac
done

printf '%s\n' "$*" >>"$CURL_LOG"

case "${STUB_CURL_MODE:-success}" in
success)
	exit 0
	;;
not-listening)
	exit 7
	;;
http-error)
	if [[ "$fail_on_http" == "true" ]]; then
		exit 22
	fi
	exit 0
	;;
esac
SCRIPT
	chmod +x "$TESTDIR/curl"
}

teardown() {
	rm -rf "$TESTDIR"
}

mark_stack_ready() {
	touch "$READY_FILE"
}

run_healthcheck() {
	PATH="$TESTDIR:$PATH" \
		CURL_LOG="$CURL_LOG" \
		STUB_CURL_MODE="$1" \
		sh "$TESTDIR/healthcheck.sh"
}

@test "fails without probing services before the stack is ready" {
	run run_healthcheck success

	[ "$status" -eq 1 ]
	[[ "$output" == *"LGTM stack is not ready"* ]]
	[ ! -e "$CURL_LOG" ]
}

@test "skips services that are not listening after the stack is ready" {
	mark_stack_ready
	run run_healthcheck not-listening

	[ "$status" -eq 0 ]
	[[ "$output" == *"Grafana not running (skipping)"* ]]
	[[ "$output" == *"All running services healthy"* ]]
	[ "$(wc -l <"$CURL_LOG")" -eq 5 ]
}

@test "reports successful HTTP responses as healthy" {
	mark_stack_ready
	run run_healthcheck success

	[ "$status" -eq 0 ]
	[[ "$output" == *"Grafana healthy"* ]]
	[[ "$output" == *"All running services healthy"* ]]
}

@test "reports HTTP error responses as unhealthy" {
	mark_stack_ready
	run run_healthcheck http-error

	[ "$status" -eq 1 ]
	[[ "$output" == *"Grafana unhealthy"* ]]
	[ "$(wc -l <"$CURL_LOG")" -eq 1 ]
}
