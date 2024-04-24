#!/bin/bash

RELEASE=${1:-dev}

docker run \
  --name lgtm \
  -p 3000:3000 \
  -p 4317:4317 \
  -p 4318:4318 \
  --rm \
  -ti \
  -v $PWD/container/grafana:/data/grafana \
  -v $PWD/container/prometheus:/data/prometheus \
  -v $PWD/container/loki:/loki \
  -e GF_PATHS_DATA=/data/grafana \
  localhost/grafana/otel-lgtm:${RELEASE}