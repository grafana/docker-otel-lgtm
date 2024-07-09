@REM @echo off

if not exist ./target/rolldice.jar (
    mvnw clean package
)

set version=v2.1.0
set jar=opentelemetry-javaagent-%version%.jar
if not exist ./%jar% (
    curl -sL https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/%version%/opentelemetry-javaagent.jar -o %jar%
)

set OTEL_RESOURCE_ATTRIBUTES=service.name=rolldice,service.instance.id=localhost:8080
@REM uncomment the next line to switch to Prometheus native histograms.
@REM set OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION=base2_exponential_bucket_histogram
java -Dotel.metric.export.interval=500 -Dotel.bsp.schedule.delay=500 -javaagent:%jar% -jar ./target/rolldice.jar
