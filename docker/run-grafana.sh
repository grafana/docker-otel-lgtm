#!/bin/bash

source ./logging.sh

cd ./grafana
run_with_logging "Grafana ${GRAFANA_VERSION}" "${ENABLE_LOGS_GRAFANA:-false}" ./bin/grafana server
