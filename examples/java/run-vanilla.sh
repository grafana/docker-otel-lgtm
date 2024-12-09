#!/bin/bash

set -euox pipefail

./mvnw clean package
jar=opentelemetry-javaagent-2.10.0.jar

function run() {
    service=$1
    port=$2
    ps aux | grep "$service" | grep -v grep | awk '{print $2}' | xargs kill -9 || true

    export SERVER_PORT=$port
    export OTEL_RESOURCE_ATTRIBUTES="service.name=$service,service.instance.id=$service"
    # uncomment the next line to switch to Prometheus native histograms.
    # export OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION=base2_exponential_bucket_histogram
    java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:${jar} -jar ./"$service"/target/"$service".jar &
}

run frontend 8081
run checkout 8082
run cart 8083
