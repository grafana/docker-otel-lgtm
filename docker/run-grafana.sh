#!/bin/bash

source ./logging.sh

if [ -z "${GF_AUTH_ANONYMOUS_ENABLED:-}" ]; then
	export GF_AUTH_ANONYMOUS_ENABLED=true
	export GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
fi

export GF_PATHS_HOME=/data/grafana
export GF_PATHS_DATA=/data/grafana/data
export GF_PATHS_PLUGINS=/data/grafana/plugins

cd ./grafana
run_with_logging "Grafana ${GRAFANA_VERSION}" "${ENABLE_LOGS_GRAFANA:-false}" ./bin/grafana server
