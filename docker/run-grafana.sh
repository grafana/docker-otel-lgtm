#!/bin/bash

source ./logging.sh

# Respect user-provided environment variables and apply defaults only if unset
export GF_AUTH_ANONYMOUS_ENABLED="${GF_AUTH_ANONYMOUS_ENABLED:-true}"

# Only set anonymous org role when anonymous auth is enabled
if [ "${GF_AUTH_ANONYMOUS_ENABLED}" != "false" ]; then
  export GF_AUTH_ANONYMOUS_ORG_ROLE="${GF_AUTH_ANONYMOUS_ORG_ROLE:-Admin}"
fi

export GF_PATHS_HOME=/data/grafana
export GF_PATHS_DATA=/data/grafana/data
export GF_PATHS_PLUGINS=/data/grafana/plugins

# pyroscope settings:
# profiles drilldown connects to this plugin automatically - so we install it (even though it does nothing)
if [ -n "${GF_PLUGINS_PREINSTALL:-}" ]; then
	export GF_PLUGINS_PREINSTALL="${GF_PLUGINS_PREINSTALL},grafana-llm-app"
else
	export GF_PLUGINS_PREINSTALL=grafana-llm-app
fi

cd /otel-lgtm/grafana || exit 1
run_with_logging "Grafana ${GRAFANA_VERSION}" "${ENABLE_LOGS_GRAFANA:-false}" ./bin/grafana server
