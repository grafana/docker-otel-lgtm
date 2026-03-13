#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}

echo "Building the Grafana OTEL-LGTM image with release ${RELEASE}..."

if command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
else
	echo "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
	exit 1
fi

if [ "$RUNTIME" = "podman" ]; then
	TAG="localhost/grafana/otel-lgtm:${RELEASE}"
else
	TAG="grafana/otel-lgtm:${RELEASE}"
fi

$RUNTIME buildx build -f docker/Dockerfile docker --tag "$TAG" --build-arg LGTM_VERSION="${RELEASE}"

# Ensure the image is also available without localhost/ prefix (for tools like oats)
if [ "$RUNTIME" = "podman" ]; then
	$RUNTIME tag "$TAG" "grafana/otel-lgtm:${RELEASE}"
fi
