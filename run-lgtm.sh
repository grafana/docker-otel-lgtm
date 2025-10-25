#!/bin/bash

RELEASE=${1:-latest}

docker pull docker.io/grafana/otel-lgtm:"${RELEASE}"

# Create necessary directories for volume mounts
mkdir -p container/grafana container/prometheus container/loki

touch .env

docker run \
	--name lgtm \
	-p 3000:3000 \
	-p 4317:4317 \
	-p 4318:4318 \
	--rm \
	-ti \
	-v "$PWD"/container/grafana:/data/grafana \
	-v "$PWD"/container/prometheus:/data/prometheus \
	-v "$PWD"/container/loki:/data/loki \
	-e GF_PATHS_DATA=/data/grafana \
	--env-file .env \
	docker.io/grafana/otel-lgtm:"${RELEASE}"
