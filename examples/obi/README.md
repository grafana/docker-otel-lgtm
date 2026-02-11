# OBI (OpenTelemetry eBPF Instrumentation) Example

This example demonstrates [OBI](https://github.com/open-telemetry/opentelemetry-go-instrumentation)
(OpenTelemetry eBPF Instrumentation, formerly Grafana Beyla) automatically instrumenting
5 applications written in different languages — **without any code changes or OpenTelemetry SDKs**.

## What is OBI?

OBI uses Linux eBPF to hook into kernel-level events (network I/O, function calls) to
automatically generate OpenTelemetry traces and metrics for HTTP/gRPC services. Unlike
traditional instrumentation that requires SDK integration, agents, or code changes, OBI
works at the kernel level and can instrument any application regardless of language.

## How it works

<!-- editorconfig-checker-disable -->

```text
+--------------------------------------------------------------------+
|  lgtm container (privileged, pid: host)                            |
|                                                                    |
|  +-----------+  +------------+  +-------+  +------+  +----------+  |
|  | OBI (eBPF)|->| OTel       |->| Tempo |  | Loki |  |Prometheus|  |
|  |           |  | Collector  |  +-------+  +------+  +----------+  |
|  +-----+-----+  +------------+       ^                     ^       |
|        |              |               +---------------------+      |
|        | eBPF hooks   |                    Grafana :3000           |
+--------+--------------+--------------------------------------------+
         | observes     |
    +----+--------------+------------------------------------------+
    |              Host kernel (shared via pid: host)              |
    +--------+------+--------+---------+-----------+               |
    |  Java  |  Go  | Python | Node.js |  .NET     |               |
    |  :8080 |:8081 | :8082  |  :8084  |  :8083    |               |
    |        |      |        |         |           |               |
    |  (no OTel SDK, agent, or distro in any app)  |               |
    +--------+------+--------+---------+-----------+               |
    +--------------------------------------------------------------+
```

<!-- editorconfig-checker-enable -->

1. The `lgtm` container runs with `privileged: true` and `pid: "host"`, giving OBI access
   to the host kernel and all container processes.
2. OBI attaches eBPF probes to the kernel to observe HTTP traffic patterns.
3. It automatically generates traces and metrics and sends them to the OpenTelemetry Collector.
4. The Collector forwards data to Tempo (traces) and Prometheus (metrics).
5. Grafana provides a UI to explore all telemetry data.

## Prerequisites

- **Linux host** (eBPF is a Linux kernel feature)
- **Kernel 5.8+** (required for eBPF ring buffer support)
- **Docker** with support for `privileged` containers and `pid: "host"`
- Note: This example does **not** work on Docker Desktop for macOS/Windows due to eBPF
  limitations in the Linux VM.

## Quick start

```bash
docker compose up --build
```

Wait for all services to start (the traffic generator will begin sending requests
to all 5 apps automatically).

## What you'll see in Grafana

Open [http://localhost:3000](http://localhost:3000) (no login required).

### Traces (Tempo)

1. Go to **Explore** → select **Tempo** data source
2. Use the **Search** tab to find traces
3. You should see HTTP traces for `/rolldice` from all 5 services

### Metrics (Prometheus)

1. Go to **Explore** → select **Prometheus** data source
2. Query HTTP metrics, e.g.:
   - `http_server_request_duration_seconds_bucket` — request duration histogram
   - `http_server_request_duration_seconds_count` — request count

## Applications

All 5 applications implement the same `/rolldice` endpoint returning a random number 1–6.
**None** of them include any OpenTelemetry instrumentation:

| Language | Port | Source                        | What's different from `../` version   |
|----------|------|-------------------------------|---------------------------------------|
| Java     | 8080 | Reuses `../java` source       | No OTel Java agent                    |
| Go       | 8081 | `./go/` (new minimal source)  | No `otelhttp`, no OTel SDK            |
| Python   | 8082 | Reuses `../python` source     | No `opentelemetry-distro`             |
| .NET     | 8083 | `./dotnet/` (new minimal)     | No OTel NuGet packages                |
| Node.js  | 8084 | `./nodejs/` (new minimal)     | No `@opentelemetry/*` packages        |

## Comparison: OBI vs traditional instrumentation

| Aspect                | Traditional (SDK/Agent)       | OBI (eBPF)                  |
|-----------------------|-------------------------------|-----------------------------|
| Code changes required | Yes (SDK) or agent config     | None                        |
| Language support      | Per-language SDK              | Language-agnostic           |
| Trace detail          | Full custom spans, attributes | HTTP/gRPC-level spans       |
| Metrics               | Custom + auto                 | HTTP request metrics        |
| Deployment            | Per-app configuration         | Single privileged container |
| Kernel requirement    | None                          | Linux 5.8+                  |
| Overhead              | In-process                    | Kernel-level (minimal)      |

## Configuration

OBI is configured via environment variables on the `lgtm` container:

- `ENABLE_OBI: "true"` — enables OBI inside the LGTM container
- `OTEL_EXPORTER_OTLP_ENDPOINT` — where OBI sends telemetry (defaults to local collector)

See the [OBI documentation](https://grafana.com/docs/grafana-cloud/monitor-applications/beyla/)
for additional configuration options like route decoration, service name mapping, and filtering.

## Limitations

- **Linux only** — eBPF is a Linux kernel feature; does not work on macOS/Windows hosts
- **Privileged mode required** — the container needs elevated permissions for eBPF
- **HTTP/gRPC only** — OBI instruments network protocols, not application-internal logic
- **No custom spans** — unlike SDK instrumentation, you cannot add custom spans or attributes
- **No logs** — OBI generates traces and metrics, not logs
