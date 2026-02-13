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

$RUNTIME buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:"${RELEASE}" --build-arg LGTM_VERSION="${RELEASE}"
