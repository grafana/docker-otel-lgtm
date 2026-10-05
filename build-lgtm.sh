#!/usr/bin/env bash

set -euo pipefail

RELEASE=${1:-latest}
CONTAINER_RUNTIME_OVERRIDE=${2:-${CONTAINER_RUNTIME_OVERRIDE:-}}

echo "Building the Grafana OTEL-LGTM image with release ${RELEASE}..."

if [ -n "$CONTAINER_RUNTIME_OVERRIDE" ]; then
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
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
elif command -v container >/dev/null 2>&1; then
	RUNTIME=apple_container
else
	echo "Unable to find a suitable container runtime such as Docker, Podman, or Apple Container. Exiting."
	exit 1
fi

if [ "$RUNTIME" = "podman" ]; then
	TAG="localhost/grafana/otel-lgtm:${RELEASE}"
else
	TAG="grafana/otel-lgtm:${RELEASE}"
fi

if [ "$RUNTIME" = "apple_container" ]; then
	if ! container system status >/dev/null 2>&1; then
		echo "Apple Container services are not running. Run 'container system start', then retry." >&2
		exit 1
	fi
	container build -f docker/Dockerfile -t "${TAG}" --build-arg LGTM_VERSION="${RELEASE}" docker
else
	"$RUNTIME" buildx build -f docker/Dockerfile docker --tag "${TAG}" --build-arg LGTM_VERSION="${RELEASE}"
fi

# Ensure the image is also available without localhost/ prefix (for tools like oats)
if [ "$RUNTIME" = "podman" ]; then
	"$RUNTIME" tag "${TAG}" "grafana/otel-lgtm:${RELEASE}"
fi
