# Java Example

Spring Boot application instrumented with OpenTelemetry Java Agent.

## Run with Docker Compose

This example includes a custom Grafana dashboard and sets it as the home dashboard.

```bash
docker-compose up -d
```

Generate traffic:

```bash
curl http://127.0.0.1:8080/rolldice
```

Access services:

- Grafana: <http://127.0.0.1:3000> (admin/admin)
- Application: <http://127.0.0.1:8080/rolldice>

The custom dashboard loads automatically as the home dashboard.

## Run with Standalone Dockerfile

```bash
docker build -t java-rolldice .
docker run -p 8080:8080 \
  -e OTEL_SERVICE_NAME=rolldice \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318 \
  java-rolldice
```

## Custom Dashboard

The custom dashboard (`custom-dashboard.json`) displays:

- Request rate for the `/rolldice` endpoint
- Response time percentiles (p50, p95)

To modify the dashboard, edit `custom-dashboard.json` and restart the lgtm container:

```bash
docker-compose restart lgtm
```