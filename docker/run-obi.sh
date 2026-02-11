#!/bin/bash

source ./logging.sh

# Map friendly language names to OBI's OTEL_EBPF_AUTO_TARGET_EXE
case "${OBI_TARGET:-}" in
java) export OTEL_EBPF_AUTO_TARGET_EXE="java" ;;
python) export OTEL_EBPF_AUTO_TARGET_EXE="python|python3" ;;
node) export OTEL_EBPF_AUTO_TARGET_EXE="node" ;;
dotnet) export OTEL_EBPF_AUTO_TARGET_EXE="dotnet" ;;
ruby) export OTEL_EBPF_AUTO_TARGET_EXE="ruby" ;;
go) echo "Note: Go binaries have no common executable name. Use OTEL_EBPF_OPEN_PORT or OTEL_EBPF_AUTO_TARGET_EXE with your binary name." ;;
"") ;;                                                      # use default port-based discovery (see below)
*) export OTEL_EBPF_AUTO_TARGET_EXE="${OBI_TARGET}" ;; # pass through as regex
esac

# Default to port-based discovery when no specific target or port is configured
if [[ -z ${OTEL_EBPF_AUTO_TARGET_EXE:-} && -z ${OTEL_EBPF_OPEN_PORT:-} ]]; then
	export OTEL_EBPF_OPEN_PORT="80,443,8080-8099,3000-3999,5000-5999"
fi

run_with_logging "OBI ${OBI_VERSION}" "${ENABLE_LOGS_OBI:-false}" ./obi/obi --config=./obi-config.yaml
