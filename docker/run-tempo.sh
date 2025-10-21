#!/bin/bash

source ./logging.sh

run_with_logging "Tempo ${TEMPO_VERSION}" "true" ./tempo/tempo --config.file=./tempo-config.yaml
