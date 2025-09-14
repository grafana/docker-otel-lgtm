#!/bin/bash

set -euox pipefail

if [[ ! -f ./target/rolldice.jar ]]; then
	./mvnw clean package
fi

# renovate: datasource=github-releases depName=opentelemetry-java-instrumentation packageName=open-telemetry/opentelemetry-java-instrumentation
opentelemetry_javaagent_version=2.20.0
jar=opentelemetry-javaagent-${opentelemetry_javaagent_version}.jar
if [[ ! -f ./${jar} ]]; then
	curl -vL https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${opentelemetry_javaagent_version}/opentelemetry-javaagent.jar -o ${jar} # editorconfig-checker-disable-line

fi
export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,service.instance.id=127.0.0.1:8080"
# uncomment the next line to switch to Prometheus native histograms.
# export OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION=base2_exponential_bucket_histogram
java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:${jar} -jar ./target/rolldice.jar
