#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	BINDIR="$TESTDIR/bin"
	mkdir -p "$BINDIR"
	mkdir -p "$TESTDIR/work/container"/{grafana,prometheus,loki}
	cp "$BATS_TEST_DIRNAME/run-lgtm.sh" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/run-lgtm.ps1" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/run-lgtm.cmd" "$TESTDIR/work/"

	for runtime in podman docker; do
		cat >"$BINDIR/$runtime" <<'SCRIPT'
#!/usr/bin/env bash
exit 0
SCRIPT
		chmod +x "$BINDIR/$runtime"
	done
}

teardown() {
	rm -rf "$TESTDIR"
}

run_launcher() {
	cd "$TESTDIR/work" || return 1
	PATH="$BINDIR:$PATH" bash ./run-lgtm.sh "$@" --dry-run
}

assert_output_contains() {
	[[ "$output" == *"$1"* ]]
}

@test "dry-run prints preferred runtime and release-tag image" {
	run run_launcher 1.2.3 false
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=podman'
	assert_output_contains 'image=docker.io/grafana/otel-lgtm:1.2.3'
	assert_output_contains 'arg=-e'
	assert_output_contains 'arg=CONTAINER_RUNTIME=podman'
	assert_output_contains 'arg=OTEL_COLLECTOR_DEBUG_EXPORTER='
	assert_output_contains 'arg=--env-file'
}

@test "dry-run local image uses requested release tag for preferred runtime" {
	run run_launcher 1.2.3 true
	[ "$status" -eq 0 ]
	assert_output_contains 'image=localhost/grafana/otel-lgtm:1.2.3'
}

@test "dry-run includes OBI flags when enabled from environment" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" ENABLE_OBI=true bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'arg=--pid=host'
	assert_output_contains 'arg=--privileged'
	assert_output_contains 'arg=ENABLE_OBI=true'
}

@test "powershell launcher forwards OTEL collector debug exporter in dry-run output" {
	grep -Fq 'OTEL_COLLECTOR_DEBUG_EXPORTER=' "$TESTDIR/work/run-lgtm.ps1"
	grep -Fq 'if ('"$"'DryRun)' "$TESTDIR/work/run-lgtm.ps1"
}

@test "cmd wrapper passes local image flag and dry-run switch correctly" {
	grep -Fq 'set "localimg=%~2"' "$TESTDIR/work/run-lgtm.cmd"
	grep -Fq 'if /I "%~3"=="--dry-run" set "dryrun=-DryRun"' "$TESTDIR/work/run-lgtm.cmd"
}
