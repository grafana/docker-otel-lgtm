#!/bin/bash

set -euo pipefail

RELEASE=${1:-latest}
LOCAL_VOLUME=${PWD}/container
# Only set this to "true" if you built the image with 'build-lgtm.sh' script
USE_LOCAL_IMAGE=${2:-false}

for dir in grafana prometheus loki
  do
    test -d ${LOCAL_VOLUME}/${dir} || mkdir -p ${LOCAL_VOLUME}/${dir}
done

test -f .env || touch .env

if command -v docker >/dev/null 2>&1
  then
    RUNTIME=docker
    MOUNT_OPTS=rw
elif command -v podman >/dev/null 2>&1
  then
    RUNTIME=podman
    # Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
    # See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
    # See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
    MOUNT_OPS="rw,z"
else
  echo "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
  exit 1
fi

if [ $USE_LOCAL_IMAGE = true ]
  then
    if [ "$RUNTIME" = "podman" ]
      then
        # Default address when building with Podman.
        IMAGE="localhost/grafana/otel-lgtm:latest"
      else
        IMAGE="grafana/otel-lgtm:latest"
    fi
  else
    IMAGE="docker.io/grafana/otel-lgtm:${RELEASE}"
    $RUNTIME image pull $IMAGE
fi

$RUNTIME container run \
	--name lgtm \
	-p 3000:3000 \
	-p 4317:4317 \
	-p 4318:4318 \
	--rm \
	-ti \
	-v ${LOCAL_VOLUME}/grafana:/data/grafana:${MOUNT_OPS} \
	-v ${LOCAL_VOLUME}/prometheus:/data/prometheus:${MOUNT_OPS} \
	-v ${LOCAL_VOLUME}/loki:/data/loki:${MOUNT_OPS} \
	-e GF_PATHS_DATA=/data/grafana \
	--env-file .env \
	$IMAGE
