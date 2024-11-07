#!/bin/bash

set -euox pipefail

if [[ ! -f ./target/rolldice.jar ]] ; then
    ./mvnw clean package
fi
#version=2.10.0-SNAPSHOT
version=2.9.0
jar=opentelemetry-javaagent-${version}.jar
if [[ ! -f ./${jar} ]] ; then
    curl -sL http://us-docker.pkg.dev/grafanalabs-global/docker-grafana-opentelemetry-java-prod/grafana-opentelemetry-java:${version}/grafana-javaagent.jar -o ${jar}
fi
export OTEL_RESOURCE_ATTRIBUTES="service.name=rolldice,service.instance.id=localhost:8080"
# uncomment the next line to switch to Prometheus native histograms.
# export OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION=base2_exponential_bucket_histogram
java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:${jar} -jar ./target/rolldice.jar
