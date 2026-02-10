#!/bin/bash

source ./logging.sh

# Map friendly language names to Beyla's BEYLA_EXECUTABLE_NAME
case "${BEYLA_TARGET:-}" in
java) export BEYLA_EXECUTABLE_NAME="java" ;;
python) export BEYLA_EXECUTABLE_NAME="python|python3" ;;
node) export BEYLA_EXECUTABLE_NAME="node" ;;
dotnet) export BEYLA_EXECUTABLE_NAME="dotnet" ;;
ruby) export BEYLA_EXECUTABLE_NAME="ruby" ;;
go) echo "Note: Go binaries have no common executable name. Use BEYLA_OPEN_PORT or BEYLA_EXECUTABLE_NAME with your binary name." ;;
"") ;;                                               # use default port-based discovery (see below)
*) export BEYLA_EXECUTABLE_NAME="${BEYLA_TARGET}" ;; # pass through as regex
esac

# Default to port-based discovery when no specific target or port is configured
if [[ -z ${BEYLA_EXECUTABLE_NAME:-} && -z ${BEYLA_OPEN_PORT:-} ]]; then
	export BEYLA_OPEN_PORT="80,443,8080-8099,3000-3999,5000-5999"
fi

run_with_logging "Beyla ${BEYLA_VERSION}" "${ENABLE_LOGS_BEYLA:-false}" ./beyla/beyla --config=./beyla-config.yaml
