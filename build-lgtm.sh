#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}
CONTAINER_RUNTIME_OVERRIDE=${2:-}

echo "Building the Grafana OTEL-LGTM image with release ${RELEASE}..."

if [ -n "$CONTAINER_RUNTIME_OVERRIDE" ]; then
	case "$CONTAINER_RUNTIME_OVERRIDE" in
	docker | podman) RUNTIME="$CONTAINER_RUNTIME_OVERRIDE" ;;
	*)
		echo "Invalid runtime: $CONTAINER_RUNTIME_OVERRIDE (must be docker or podman)"
		exit 1
		;;
	esac
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
else
	echo "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
	exit 1
fi

"$RUNTIME" buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:"${RELEASE}" --build-arg LGTM_VERSION="${RELEASE}"
