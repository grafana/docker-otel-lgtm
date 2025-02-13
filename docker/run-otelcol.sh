#!/bin/bash

source ./logging.sh

config_file="otelcol-config.yaml"

if [[ -v OTEL_EXPORTER_OTLP_ENDPOINT ]]; then
	echo "Also enabling OTLP/HTTP export to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
	config_file="otelcol-config-export-http.yaml"

	if [[ -v OTEL_EXPORTER_OTLP_HEADERS ]]; then
		echo "Adding headers from OTEL_EXPORTER_OTLP_HEADERS"

    yaml_headers="{"
    # split the headers into an array on , - and then each element using =
    IFS=',' read -r -a headers <<< "$OTEL_EXPORTER_OTLP_HEADERS"
    for header in "${headers[@]}"; do
      IFS='=' read -r -a header_parts <<< "$header"
      if [[ ${#header_parts[@]} -eq 2 ]]; then
        if [[ $yaml_headers != "{" ]]; then
          yaml_headers+=", "
        fi
        yaml_headers+="'${header_parts[0]}': '${header_parts[1]}'"
      else
        echo "Invalid header: $header"
      fi
    done
    yaml_headers+="}"

    # add the contents of OTEL_EXPORTER_OTLP_HEADERS to the otelcol-config-export-http.yaml file
    # after "endpoint: ${env:OTEL_EXPORTER_OTLP_ENDPOINT}"

    sed -i "s#.*endpoint: \${env:OTEL_EXPORTER_OTLP_ENDPOINT}.*#&\n    headers: ${yaml_headers}#" "$config_file"
	fi
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" ./otelcol-contrib/otelcol-contrib --config=file:./${config_file}
