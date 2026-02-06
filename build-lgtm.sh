#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}

if command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
else
	echo "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
	exit 1
fi

$RUNTIME buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:"${RELEASE}" --build-arg LGTM_VERSION="${RELEASE}"
