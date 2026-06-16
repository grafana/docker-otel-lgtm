#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose -f ../../ci/oats-v2/docker-compose.lgtm.yml -f docker-compose.oats.yml logs lgtm \
  | grep -F "The OpenTelemetry collector and the Grafana LGTM stack are up and running. (created /tmp/ready)"
