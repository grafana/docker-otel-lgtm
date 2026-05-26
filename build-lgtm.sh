#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}

docker buildx build -f docker/Dockerfile docker --tag rcad/otel-lgtm:"${RELEASE}"
