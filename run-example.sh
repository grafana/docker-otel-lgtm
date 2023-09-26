#!/bin/bash

cd example-app
if [[ ! -f ./target/example-app.jar ]] ; then
    ./mvnw clean package
fi
if [[ ! -f ./opentelemetry-javaagent.jar ]] ; then
    curl -sOL https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.30.0/opentelemetry-javaagent.jar
fi
export OTEL_LOGS_EXPORTER=otlp
export OTEL_RESOURCE_ATTRIBUTES="service.name=example-app,service.instance.id=localhost:8080"
java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:opentelemetry-javaagent.jar -jar ./target/example-app.jar
