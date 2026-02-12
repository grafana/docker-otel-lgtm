#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}
LOCAL_VOLUME=${PWD}/container
# Only set this to "true" if you built the image with the 'build-lgtm.sh' script
USE_LOCAL_IMAGE=${2:-false}

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

if command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
	# Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
	# See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
	# See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
	MOUNT_OPTS="rw,z"
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
	MOUNT_OPTS=rw
else
	echo "Unable to find a suitable container runtime such as Podman or Docker. Exiting."
	exit 1
fi

if [ "$USE_LOCAL_IMAGE" = true ]; then
	if [ "$RUNTIME" = "podman" ]; then
		# Default address when building with Podman.
		IMAGE="localhost/grafana/otel-lgtm:latest"
	else
		IMAGE="grafana/otel-lgtm:latest"
	fi
else
	IMAGE="docker.io/grafana/otel-lgtm:${RELEASE}"
	$RUNTIME image pull "$IMAGE"
fi

$RUNTIME container run \
	--name lgtm \
	"${OBI_FLAGS[@]}" \
	"${OBI_ENV_FLAGS[@]}" \
	-p 3000:3000 \
	-p 4040:4040 \
	-p 4317:4317 \
	-p 4318:4318 \
	-p 9090:9090 \
	--rm \
	"${TTY_FLAGS[@]}" \
	-v "${LOCAL_VOLUME}"/grafana:/data/grafana:"${MOUNT_OPTS}" \
	-v "${LOCAL_VOLUME}"/prometheus:/data/prometheus:"${MOUNT_OPTS}" \
	-v "${LOCAL_VOLUME}"/loki:/data/loki:"${MOUNT_OPTS}" \
	-e GF_PATHS_DATA=/data/grafana \
	--env-file .env \
	"$IMAGE"
