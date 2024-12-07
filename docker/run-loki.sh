#!/bin/bash

source ./logging.sh

mkdir -p /data/loki

run_with_logging "Loki ${LOKI_VERSION}" "${ENABLE_LOGS_LOKI:-false}" ./loki/loki-linux-${TARGETARCH}  --config.file=./loki-config.yaml
