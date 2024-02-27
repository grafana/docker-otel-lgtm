# docker-otel-lgtm

[grafana/otel-lgtm](https://hub.docker.com/r/grafana/otel-lgtm) bundles Grafana's open source stack for OpenTelemetry monitoring in a single Docker image.

![alt](img/overview.png)

## Intended Usage

The intended usage is:

* Quick way to try OSS Grafana with OpenTelemetry.
* Demos, presentations.
* Integration tests for OpenTelemetry instrumentation: Run automated queries against the databases to check if expected metrics/traces/logs are present.

The Docker image is not intended for production monitoring.

> ![](https://grafana.com/static/img/menu/application-observability.svg) If you are looking for an production-ready out-of-the box solution to monitor applications and minimize MTTR (mean time to resolution) with OpenTelemetry and Prometheus try [Grafana Cloud Application Observability](https://grafana.com/products/cloud/application-observability/).

## Get the Docker image

The Docker image is available on Docker hub: https://hub.docker.com/r/grafana/otel-lgtm

## Run the Docker image

```sh
./run-lgtm.sh
```

## Send OpenTelemetry Data

There's no need to configure anything: The Docker image works with OpenTelemetry's defaults.

```sh
# Not needed as these are the defaults in OpenTelemetry:
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

## View Grafana

Log in to [http://localhost:3000](http://localhost:3000) with user _admin_ and password _admin_.

## Build the Docker image from scratch

```sh
cd docker/
docker build . -t grafana/otel-lgtm
```

## Build and run the example app

Run the example REST service:

```sh
./run-example.sh
```

Generate traffic:

```sh
./generate-traffic.sh
```

## Run example apps in different languages

The example apps are in the `examples/` directory.
Each example has a `run.sh` script to start the app.

Every example implements a rolldice service, which returns a random number between 1 and 6.

Each example uses a different application port (to be able to run all applications at the same time).

| Example | Service URL                           |
|---------|---------------------------------------|
| Java    | `curl http://localhost:8080/rolldice` |
| Go      | `curl http://localhost:8081/rolldice` |
| Python  | `curl http://localhost:8082/rolldice` |

