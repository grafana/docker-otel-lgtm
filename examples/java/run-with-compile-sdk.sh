#!/bin/bash

set -euox pipefail

./mvnw clean package

pushd ~/source/otel-distro/
./gradlew clean assemble
cp agent/build/libs/grafana-opentelemetry-java.jar ~/source/docker-otel-lgtm/examples/java
popd

jar=grafana-opentelemetry-java.jar

function run() {
    local service=$1
    local port=$2
    local debug=${3:-}
    ps aux | grep java | grep "$service" | grep -v grep | awk '{print $2}' | xargs kill -9 || true

    export SERVER_PORT=$port
    export OTEL_RESOURCE_ATTRIBUTES="service.name=$service,service.instance.id=$service"
    # uncomment the next line to switch to Prometheus native histograms.
    # export OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION=base2_exponential_bucket_histogram
    java $debug -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:${jar} -jar ./"$service"/target/"$service".jar &
}

run frontend 8081
run checkout 8082 '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5006'
run cart 8083     '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005'
run auth 8084
