#!/bin/bash

set -euo pipefail

function run_with_logging() {
	name=$1
	shift
	envvar=$1
	shift
	if [[ ${envvar} == "true" || ${ENABLE_LOGS_ALL:-false} == "true" ]]; then
		echo "Running ${name} logging=true"
		exec "$@"
	else
		echo "Running ${name} logging=false"
		exec "$@" >/dev/null 2>&1
	fi
}
