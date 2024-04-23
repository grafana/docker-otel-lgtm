#!/bin/bash

RELEASE=${1:-dev}

docker buildx build -f docker/Dockerfile docker --tag grafana/otel-lgtm:${RELEASE}