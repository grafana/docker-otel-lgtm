#!/bin/bash

set -euo pipefail

if [[ ! -f ./target/example-app.jar ]] ; then
    ./mvnw clean package
fi
version=v2.0.0
jar=opentelemetry-javaagent-${version}.jar
if [[ ! -f ./${jar} ]] ; then
    curl -sL https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.0.0/opentelemetry-javaagent.jar -o ${jar}
fi
export OTEL_RESOURCE_ATTRIBUTES="service.name=example-app,service.instance.id=localhost:8080"
java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:${jar} -jar ./target/example-app.jar
