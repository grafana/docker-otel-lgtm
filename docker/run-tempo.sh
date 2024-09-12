#!/bin/bash

source ./logging.sh

run_with_logging "Tempo ${TEMPO_VERSION}" "${ENABLE_LOGS_TEMPO:-false}" ./tempo/tempo --config.file=./tempo-config.yaml > /dev/null 2>&1
