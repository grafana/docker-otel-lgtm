#!/bin/bash

source ./logging.sh

config_file="otelcol-config.yaml"

if [[ -v OTEL_EXPORTER_OTLP_ENDPOINT ]]; then
	echo "Also enabling OTLP/HTTP export to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
	config_file="otelcol-config-export-http.yaml"

	if [[ -v OTEL_EXPORTER_OTLP_HEADERS ]]; then
		echo "Adding basic auth to OTLP/HTTP export"
		config_file="otelcol-config-export-http-auth.yaml"

		# fail if the headers do not start with "Authorization=Basic "
		if [[ ! ${OTEL_EXPORTER_OTLP_HEADERS} =~ ^Authorization=Basic\  ]]; then
			echo "OTEL_EXPORTER_OTLP_HEADERS must start with 'Authorization Basic '"
			exit 1
		fi
		# fail if there are multiple headers, separated by commas
		if [[ ${OTEL_EXPORTER_OTLP_HEADERS} =~ , ]]; then
			echo "OTEL_EXPORTER_OTLP_HEADERS must not contain commas"
			exit 1
		fi

		# remove "Authorization=Basic " prefix
		username=$(echo "${OTEL_EXPORTER_OTLP_HEADERS#* }" | base64 -d | cut -d: -f1)
		password=$(echo "${OTEL_EXPORTER_OTLP_HEADERS#* }" | base64 -d | cut -d: -f2)
		export OTEL_EXPORTER_OTLP_USERNAME=${username}
		export OTEL_EXPORTER_OTLP_PASSWORD=${password}
	fi
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" ./otelcol-contrib/otelcol-contrib --config=file:./${config_file}
