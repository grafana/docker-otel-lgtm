#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
	unset CONTAINER_RUNTIME_OVERRIDE LGTM_CONTAINER_MEMORY ENABLE_OBI RUNTIME_COMMAND
	TESTDIR=$(mktemp -d)
	BINDIR="$TESTDIR/bin"
	mkdir -p "$BINDIR"
	mkdir -p "$TESTDIR/work/container"/{grafana,prometheus,loki}
	cp "$BATS_TEST_DIRNAME/run-lgtm.sh" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/run-lgtm.ps1" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/run-lgtm.cmd" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/build-lgtm.sh" "$TESTDIR/work/"
	cp "$BATS_TEST_DIRNAME/build-lgtm.cmd" "$TESTDIR/work/"

	for runtime in podman docker container wslc; do
		cat >"$BINDIR/$runtime" <<SCRIPT
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$TESTDIR/\$(basename "\$0").log"
exit 0
SCRIPT
		chmod +x "$BINDIR/$runtime"
	done

	# Default uname mock: report Linux so that most tests work (override tests
	# use CONTAINER_RUNTIME_OVERRIDE and don't rely on auto-detection).
	cat >"$BINDIR/uname" <<'SCRIPT'
#!/usr/bin/env bash
echo "Linux"
SCRIPT
	chmod +x "$BINDIR/uname"
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

# Build an isolated bin directory so real runtimes on the host (docker, podman)
# can never be found. It contains only:
#   - symlinks to the basic tools the launcher script needs
#   - a mock "uname" that prints the given value
#   - mock runtimes (each one just exits 0)
# Usage: make_isolated_bin DIR UNAME_OUTPUT [runtime ...]
make_isolated_bin() {
	local dir="$1" uname_output="$2" tool src
	shift 2
	mkdir -p "$dir"
	for tool in bash env cat dirname basename grep sed awk tr cut head tail mkdir rm mktemp id touch test; do
		src=$(command -v "$tool") || continue
		[[ "$src" == /* ]] && ln -sf "$src" "$dir/$tool"
	done
	printf '#!/usr/bin/env bash\necho "%s"\n' "$uname_output" >"$dir/uname"
	chmod +x "$dir/uname"
	for tool in "$@"; do
		printf '#!/usr/bin/env bash\nexit 0\n' >"$dir/$tool"
		chmod +x "$dir/$tool"
	done
}

# Simulate a WSL environment for auto-detection tests.
# Intercepts grep so that "grep -qi microsoft /proc/version" succeeds.
# Usage: make_wsl_bin DIR [runtime ...]
make_wsl_bin() {
	local dir="$1"
	shift
	make_isolated_bin "$dir" "Linux" "$@"
	# Replace the real grep with a wrapper that fakes /proc/version for the
	# Microsoft check, but delegates everything else to the real grep.
	local real_grep
	real_grep=$(command -v grep)
	cat >"$dir/grep" <<SCRIPT
#!/usr/bin/env bash
for arg in "\$@"; do
	if [[ "\$arg" == */proc/version ]]; then
		echo "Linux version 5.15.167.4-microsoft-standard-WSL2" | "$real_grep" "\${@:1:\$#-1}" -
		exit \$?
	fi
done
exec "$real_grep" "\$@"
SCRIPT
	chmod +x "$dir/grep"
}

@test "dry-run prints preferred runtime and release-tag image" {
	run run_launcher 1.2.3 false
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=podman'
	assert_output_contains 'image=docker.io/grafana/otel-lgtm:1.2.3'
	assert_output_contains 'arg=-e'
	[[ "$output" != *'arg=CONTAINER_RUNTIME='* ]]
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

@test "dry-run Apple Container override takes precedence and uses default memory" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=container \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=container'
	[[ "$output" != *'arg=CONTAINER_RUNTIME='* ]]
	assert_output_contains $'arg=--memory\narg=2G'
}

@test "dry-run Apple Container honors the memory override" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=container LGTM_CONTAINER_MEMORY=4G \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains $'arg=--memory\narg=4G'
}

@test "Apple Container rejects OBI eBPF auto-instrumentation" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=container ENABLE_OBI=true \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 1 ]
	assert_output_contains 'Error: OBI eBPF auto-instrumentation requires --pid=host --privileged'
	assert_output_contains 'which Apple Container does not support.'
}

@test "wslc rejects OBI eBPF auto-instrumentation" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=wslc ENABLE_OBI=true \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 1 ]
	assert_output_contains 'Error: OBI eBPF auto-instrumentation requires --pid=host --privileged'
	assert_output_contains 'which WSL containers (wslc) does not support.'
}

@test "invalid runtime override is rejected" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=invalid \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 1 ]
	assert_output_contains 'Invalid runtime: invalid (must be docker, podman, container, or wslc)'
}

@test "powershell launcher forwards OTEL collector debug exporter in dry-run output" {
	grep -Fq 'OTEL_COLLECTOR_DEBUG_EXPORTER=' "$TESTDIR/work/run-lgtm.ps1"
	grep -Fq 'if ('"$"'DryRun)' "$TESTDIR/work/run-lgtm.ps1"
}

@test "cmd wrapper passes local image flag and dry-run switch correctly" {
	grep -Fq 'set "localimg=%~2"' "$TESTDIR/work/run-lgtm.cmd"
	grep -Fq 'if /I "%~3"=="--dry-run" set "dryrun=-DryRun"' "$TESTDIR/work/run-lgtm.cmd"
}

@test "dry-run wslc override uses wslc and omits --init" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=wslc \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=wslc'
	# The main behavioural change: --init must be absent for wslc
	[[ "$output" != *'arg=--init'* ]]
}

@test "dry-run docker override includes --init" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=docker \
		bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=docker'
	assert_output_contains 'arg=--init'
}

@test "dry-run auto-detects wslc when podman and docker are absent" {
	make_wsl_bin "$TESTDIR/wslc-only" wslc
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/wslc-only" bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=wslc'
}

@test "dry-run wslc is chosen over container when both exist under WSL" {
	make_wsl_bin "$TESTDIR/both" wslc container
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/both" bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=wslc'
	[[ "$output" != *'runtime=container'* ]]
}

@test "dry-run still selects Apple Container on macOS when only container exists" {
	make_isolated_bin "$TESTDIR/mac" "Darwin" container
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/mac" LGTM_CONTAINER_MEMORY=2G bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=container'
}


@test "wslc is not auto-detected on plain Linux" {
	make_isolated_bin "$TESTDIR/linux-wslc" "Linux" wslc
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/linux-wslc" bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 1 ]
	assert_output_contains 'Unable to find a suitable container runtime'
}

@test "wslc is not auto-detected on macOS" {
	make_isolated_bin "$TESTDIR/mac-wslc" "Darwin" wslc
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/mac-wslc" bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 1 ]
	assert_output_contains 'Unable to find a suitable container runtime'
}

@test "wslc auto-detected under WSL omits --init" {
	make_wsl_bin "$TESTDIR/wsl-init" wslc
	cd "$TESTDIR/work" || return 1
	run env PATH="$TESTDIR/wsl-init" bash ./run-lgtm.sh latest false --dry-run
	[ "$status" -eq 0 ]
	assert_output_contains 'runtime=wslc'
	[[ "$output" != *'arg=--init'* ]]
}

@test "build-lgtm.sh with wslc override builds image with wslc" {
	cd "$TESTDIR/work" || return 1
	run env PATH="$BINDIR:$PATH" CONTAINER_RUNTIME_OVERRIDE=wslc \
		bash ./build-lgtm.sh dev1
	[ "$status" -eq 0 ]
	grep -Fq 'build -f docker/Dockerfile' "$TESTDIR/wslc.log"
	grep -Fq 'grafana/otel-lgtm:dev1' "$TESTDIR/wslc.log"
}

@test "build-lgtm.cmd contains wslc detection and build target" {
	grep -Fq 'WHERE /Q wslc' "$TESTDIR/work/build-lgtm.cmd"
	grep -Fq 'wslc build -f docker/Dockerfile' "$TESTDIR/work/build-lgtm.cmd"
}

@test "powershell launcher omits --init and rejects OBI for wslc" {
	grep -Fq 'if (-not $isWslc)' "$TESTDIR/work/run-lgtm.ps1"
	grep -Fq 'which WSL containers (wslc) does not support' "$TESTDIR/work/run-lgtm.ps1"
}
