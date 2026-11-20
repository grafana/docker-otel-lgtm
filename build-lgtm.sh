#!/usr/bin/env bash

set -euo pipefail

RELEASE=${1:-latest}
CONTAINER_RUNTIME_OVERRIDE=${2:-${CONTAINER_RUNTIME_OVERRIDE:-}}

echo "Building the Grafana OTEL-LGTM image with release ${RELEASE}..."

OS=$(uname -s)
# wslc auto-detection is gated to WSL (Linux kernel with a Microsoft signature).
# On native Windows, use build-lgtm.cmd instead of this script.
# CONTAINER_RUNTIME_OVERRIDE=wslc still works for any environment.
IS_WSL=false
if [ "$OS" = "Linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
	IS_WSL=true
fi

if [ -n "$CONTAINER_RUNTIME_OVERRIDE" ]; then
	case "$CONTAINER_RUNTIME_OVERRIDE" in
	docker | podman) RUNTIME="$CONTAINER_RUNTIME_OVERRIDE" ;;
	container) RUNTIME=apple_container ;;
	wslc) RUNTIME=wslc ;;
	*)
		echo "Invalid runtime: $CONTAINER_RUNTIME_OVERRIDE (must be docker, podman, container, or wslc)"
		exit 1
		;;
	esac
elif command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
elif [ "$IS_WSL" = true ] && command -v wslc >/dev/null 2>&1; then
	RUNTIME=wslc
elif [ "$OS" = "Darwin" ] && command -v container >/dev/null 2>&1; then
	RUNTIME=apple_container
else
	echo "Unable to find a suitable container runtime such as Docker, Podman, WSL containers (wslc), or Apple Container. Exiting."
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
elif [ "$RUNTIME" = "wslc" ]; then
	wslc build -f docker/Dockerfile docker --tag "${TAG}" --build-arg LGTM_VERSION="${RELEASE}"
else
	"$RUNTIME" buildx build -f docker/Dockerfile docker --tag "${TAG}" --build-arg LGTM_VERSION="${RELEASE}"
fi

# Ensure the image is also available without localhost/ prefix (for tools like oats)
if [ "$RUNTIME" = "podman" ]; then
	"$RUNTIME" tag "${TAG}" "grafana/otel-lgtm:${RELEASE}"
fi
