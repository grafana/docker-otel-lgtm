#!/usr/bin/env bash

set -euo pipefail

RELEASE=latest
# Only set this to "true" if you built the image with the 'build-lgtm.sh' script
USE_LOCAL_IMAGE=false
DRY_RUN=false
LOCAL_VOLUME=${PWD}/container

POSITIONAL_ARGS=()
for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=true ;;
	*) POSITIONAL_ARGS+=("$arg") ;;
	esac
done
RELEASE=${POSITIONAL_ARGS[0]:-latest}
USE_LOCAL_IMAGE=${POSITIONAL_ARGS[1]:-false}

for dir in grafana prometheus loki; do
	test -d "${LOCAL_VOLUME}"/${dir} || mkdir -p "${LOCAL_VOLUME}"/${dir}
done

test -f .env || touch .env

# Check if OBI is enabled (from environment or .env file)
OBI_FLAGS=()
OBI_ENV_FLAGS=()
if [[ ${ENABLE_OBI:-} == "true" ]] || grep -qE '^ENABLE_OBI=true$' .env 2>/dev/null; then
	echo "OBI eBPF auto-instrumentation enabled. Adding --pid=host --privileged flags."
	OBI_FLAGS=(--pid=host --privileged)
	# Forward OBI-specific env vars into the container (they are not in .env by default).
	# General OTLP vars (OTEL_EXPORTER_OTLP_ENDPOINT, etc.) are forwarded via --env-file .env.
	OBI_ENV_FLAGS=(-e ENABLE_OBI=true)
	for var in $(compgen -v | grep -E '^(OBI_TARGET|OTEL_EBPF_|ENABLE_LOGS_OBI)' | grep -vE '^(OBI_FLAGS|OBI_ENV_FLAGS)$'); do
		OBI_ENV_FLAGS+=(-e "$var=${!var}")
	done
fi

# Allocate TTY only if stdin is a terminal
TTY_FLAGS=()
if test -t 0; then
	TTY_FLAGS=(-t -i)
fi

if [ -n "${CONTAINER_RUNTIME_OVERRIDE:-}" ]; then
	RUNTIME_COMMAND="$CONTAINER_RUNTIME_OVERRIDE"
	case "$CONTAINER_RUNTIME_OVERRIDE" in
	docker | podman) RUNTIME="$CONTAINER_RUNTIME_OVERRIDE" ;;
	container) RUNTIME=apple_container ;;
	*)
		echo "Invalid runtime: $CONTAINER_RUNTIME_OVERRIDE (must be docker, podman, or container)"
		exit 1
		;;
	esac
elif command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
	RUNTIME_COMMAND=podman
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
	RUNTIME_COMMAND=docker
elif command -v container >/dev/null 2>&1; then
	RUNTIME=apple_container
	RUNTIME_COMMAND=container
else
	echo "Unable to find a suitable container runtime such as Podman, Docker, or Apple Container. Exiting."
	exit 1
fi

if [ "$RUNTIME" = "podman" ]; then
	# Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
	# See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
	# See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
	MOUNT_OPTS="rw,z"
else
	MOUNT_OPTS=rw
fi

if [ "$RUNTIME" = "apple_container" ]; then
	# Apple Container does not support --pid=host or --privileged, so OBI
	# eBPF auto-instrumentation cannot run under it.
	if ((${#OBI_FLAGS[@]})); then
		echo "Error: OBI eBPF auto-instrumentation requires --pid=host --privileged, which Apple Container does not support. Use Docker or Podman for OBI." >&2
		exit 1
	fi
	if [[ ${DRY_RUN} != true ]] && ! container system status >/dev/null 2>&1; then
		echo "Apple Container services are not running. Run 'container system start', then retry." >&2
		exit 1
	fi
fi

if [ "$USE_LOCAL_IMAGE" = true ]; then
	if [ "$RUNTIME" = "podman" ]; then
		# Default address when building with Podman.
		IMAGE="localhost/grafana/otel-lgtm:${RELEASE}"
	else
		IMAGE="grafana/otel-lgtm:${RELEASE}"
	fi
else
	IMAGE="docker.io/grafana/otel-lgtm:${RELEASE}"
	if [[ ${DRY_RUN} != true ]]; then
		"$RUNTIME_COMMAND" image pull "$IMAGE"
	fi
fi

RUN_FLAGS=(
	--name lgtm
	--init
)

if ((${#OBI_FLAGS[@]})); then
	RUN_FLAGS+=("${OBI_FLAGS[@]}")
fi
if ((${#OBI_ENV_FLAGS[@]})); then
	RUN_FLAGS+=("${OBI_ENV_FLAGS[@]}")
fi

RUN_FLAGS+=(
	-p 3000:3000
	-p 3200:3200
	-p 4040:4040
	-p 4317:4317
	-p 4318:4318
	-p 9090:9090
	--rm
)

if ((${#TTY_FLAGS[@]})); then
	RUN_FLAGS+=("${TTY_FLAGS[@]}")
fi

RUN_FLAGS+=(
	-v "${LOCAL_VOLUME}"/grafana:/data/grafana:"${MOUNT_OPTS}"
	-v "${LOCAL_VOLUME}"/prometheus:/data/prometheus:"${MOUNT_OPTS}"
	-v "${LOCAL_VOLUME}"/loki:/data/loki:"${MOUNT_OPTS}"
	-e GF_PATHS_DATA=/data/grafana
	-e CONTAINER_RUNTIME="$RUNTIME_COMMAND"
	-e OTEL_COLLECTOR_DEBUG_EXPORTER="${OTEL_COLLECTOR_DEBUG_EXPORTER:-}"
	--env-file .env
)

if [ "$RUNTIME" = "apple_container" ]; then
	# Apple's default of 1G is too small for the stack.
	RUN_FLAGS+=(--memory "${LGTM_CONTAINER_MEMORY:-2G}")
fi

if [[ ${DRY_RUN} == true ]]; then
	echo "runtime=$RUNTIME_COMMAND"
	echo "image=$IMAGE"
	for arg in run "${RUN_FLAGS[@]}" "$IMAGE"; do
		echo "arg=$arg"
	done
	exit 0
fi

"$RUNTIME_COMMAND" run "${RUN_FLAGS[@]}" "$IMAGE"
