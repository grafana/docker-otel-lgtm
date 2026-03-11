#!/bin/bash

source ./logging.sh

secondary_config_file=""

render_external_otlp_export_config() {
	cat <<'EOF' >otelcol-config-export-http.yaml
service:
  pipelines:
EOF

	for signal in traces metrics logs; do
		local signal_var="OTEL_EXPORTER_OTLP_${signal^^}_ENDPOINT"
		if [[ -n ${!signal_var:-} ]]; then
			printf '    %s:\n      exporters: [otlphttp/%s, otlphttp/external-%s]\n' "${signal}" "${signal}" "${signal}" >>otelcol-config-export-http.yaml
		fi
	done

	cat <<'EOF' >>otelcol-config-export-http.yaml

exporters:
EOF

	for signal in traces metrics logs; do
		local signal_var="OTEL_EXPORTER_OTLP_${signal^^}_ENDPOINT"
		if [[ -n ${!signal_var:-} ]]; then
			printf '  otlphttp/external-%s:\n    endpoint: ${env:%s}\n' "${signal}" "${signal_var}" >>otelcol-config-export-http.yaml
		fi
	done
}

if [[ -n ${OTEL_EXPORTER_OTLP_ENDPOINT:-} || -n ${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-} || -n ${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-} || -n ${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-} ]]; then
	if [[ -n ${OTEL_EXPORTER_OTLP_ENDPOINT:-} ]]; then
		echo "Also enabling OTLP/HTTP export to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
	fi

	# Keep backward compatibility: if only OTEL_EXPORTER_OTLP_ENDPOINT is set,
	# use it as the per-signal endpoint fallback.
	export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"
	export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"
	export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"

	render_external_otlp_export_config
	secondary_config_file="--config=file:./otelcol-config-export-http.yaml"

	if [[ -v OTEL_EXPORTER_OTLP_HEADERS && -n ${OTEL_EXPORTER_OTLP_HEADERS} ]]; then
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

		# add the contents of OTEL_EXPORTER_OTLP_HEADERS to all external exporters in otelcol-config-export-http.yaml
		awk -v headers="${yaml_headers}" '
			{ print }
			/endpoint: \$\{env:OTEL_EXPORTER_OTLP_(TRACES|METRICS|LOGS)_ENDPOINT\}/ {
				print "    headers: " headers
			}
		' otelcol-config-export-http.yaml >otelcol-config-export-http.yaml.tmp && mv otelcol-config-export-http.yaml.tmp otelcol-config-export-http.yaml
	fi
fi

run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" \
	./otelcol-contrib/otelcol-contrib --feature-gates service.profilesSupport --config=file:./otelcol-config.yaml ${secondary_config_file}
