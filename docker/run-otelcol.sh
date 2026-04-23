#!/bin/bash

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling logging.sh

secondary_config_file=""

render_pipeline_overlay() {
	printf 'service:\n  pipelines:\n' >otelcol-config-export-http.yaml

	for signal in traces metrics logs; do
		local signal_var="OTEL_EXPORTER_OTLP_${signal^^}_ENDPOINT"
		if [[ -n ${!signal_var:-} || ${OTEL_COLLECTOR_DEBUG_EXPORTER:-false} == "true" ]]; then
			local exporters="otlp_http/${signal}"
			[[ -n ${!signal_var:-} ]] && exporters+=", otlp_http/external-${signal}"
			[[ ${OTEL_COLLECTOR_DEBUG_EXPORTER:-false} == "true" ]] && exporters+=", debug/${signal}"
			printf '    %s:\n      exporters: [%s]\n' "${signal}" "${exporters}" >>otelcol-config-export-http.yaml
		fi
	done

	if [[ -n ${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-} ||
		-n ${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-} ||
		-n ${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-} ]]; then
		printf '\nexporters:\n' >>otelcol-config-export-http.yaml
		for signal in traces metrics logs; do
			local signal_var="OTEL_EXPORTER_OTLP_${signal^^}_ENDPOINT"
			if [[ -n ${!signal_var:-} ]]; then
				# shellcheck disable=SC2016 # otelcol config template, not bash variables
				printf '  otlp_http/external-%s:\n    endpoint: ${env:%s}\n' \
					"${signal}" "${signal_var}" >>otelcol-config-export-http.yaml
			fi
		done
	fi
}

if [[ -n ${OTEL_EXPORTER_OTLP_ENDPOINT:-} ||
	-n ${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-} ||
	-n ${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-} ||
	-n ${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-} ]]; then
	if [[ -n ${OTEL_EXPORTER_OTLP_ENDPOINT:-} ]]; then
		echo "Also enabling OTLP/HTTP export to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
	fi

	# Keep backward compatibility: if only OTEL_EXPORTER_OTLP_ENDPOINT is set,
	# use it as the per-signal endpoint fallback.
	export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"
	export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"
	export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-${OTEL_EXPORTER_OTLP_ENDPOINT:-}}"
fi

if [[ ${OTEL_COLLECTOR_DEBUG_EXPORTER:-false} == "true" ]]; then
	echo "Enabling debug exporter for OpenTelemetry Collector"
fi

if [[ -n ${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-} ||
	-n ${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-} ||
	-n ${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-} ||
	${OTEL_COLLECTOR_DEBUG_EXPORTER:-false} == "true" ]]; then
	render_pipeline_overlay
	secondary_config_file="--config=file:./otelcol-config-export-http.yaml"

	if [[ -v OTEL_EXPORTER_OTLP_HEADERS && -n ${OTEL_EXPORTER_OTLP_HEADERS} &&
		(-n ${OTEL_EXPORTER_OTLP_TRACES_ENDPOINT:-} ||
		-n ${OTEL_EXPORTER_OTLP_METRICS_ENDPOINT:-} ||
		-n ${OTEL_EXPORTER_OTLP_LOGS_ENDPOINT:-}) ]]; then
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
			/endpoint: \$\{env:OTEL_EXPORTER_OTLP_(LOGS|METRICS|TRACES)_ENDPOINT\}/ {
				print "    headers: " headers
			}
		' otelcol-config-export-http.yaml >otelcol-config-export-http.yaml.tmp && mv otelcol-config-export-http.yaml.tmp otelcol-config-export-http.yaml
	fi
fi

otelcol_args=(--feature-gates service.profilesSupport --config=file:./otelcol-config.yaml)
[[ -n "${secondary_config_file}" ]] && otelcol_args+=("${secondary_config_file}")
extra_args=()
if [[ -n "${OTELCOL_EXTRA_ARGS:-}" ]]; then
	read -ra extra_args <<<"${OTELCOL_EXTRA_ARGS}"
fi
run_with_logging "OpenTelemetry Collector ${OPENTELEMETRY_COLLECTOR_VERSION}" "${ENABLE_LOGS_OTELCOL:-false}" \
	./otelcol-contrib/otelcol-contrib "${otelcol_args[@]}" "${extra_args[@]}"
