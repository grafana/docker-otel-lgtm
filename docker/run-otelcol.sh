#!/bin/bash

source ./logging.sh

secondary_config_file=""

if [[ -v OTEL_EXPORTER_OTLP_ENDPOINT ]]; then
	echo "Also enabling OTLP/HTTP export to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
	secondary_config_file="--config=file:./otelcol-config-export-http.yaml"

	if [[ -v OTEL_EXPORTER_OTLP_HEADERS ]]; then
		echo "Adding headers from OTEL_EXPORTER_OTLP_HEADERS"

		yaml_headers="{"
		# split the headers into an array on , - and then each element using =
		IFS=',' read -r -a headers <<<"$OTEL_EXPORTER_OTLP_HEADERS"
		for header in "${headers[@]}"; do
			IFS='=' read -r -a header_parts <<<"$header"
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
		printf '\n    headers: %s' "${yaml_headers}" >>otelcol-config-export-http.yaml
	fi
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" \
	./otelcol-contrib/otelcol-contrib --config=file:./otelcol-config.yaml ${secondary_config_file}
