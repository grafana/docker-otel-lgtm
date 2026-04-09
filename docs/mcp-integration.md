# AI Tool Integration (MCP)

The `grafana/otel-lgtm` image integrates with [Model Context Protocol (MCP)][mcp]
so AI coding tools (Claude, Cursor, etc.) can query your telemetry data directly.

Tempo exposes an HTTP MCP endpoint from inside the container. Grafana data is accessed
via a client-side `uvx mcp-grafana` process that runs on your machine and connects to
the Grafana instance in the container.

## What you get

- **Dashboards**: list, read, and search dashboards via client-side `uvx mcp-grafana`
- **Logs**: query via LogQL via client-side `uvx mcp-grafana`
- **Metrics**: query via PromQL via client-side `uvx mcp-grafana`
- **Traces**: query via TraceQL through Tempo's built-in HTTP MCP endpoint (in-container)

## Setup

1. Start the container:

   ```sh
   ./run-lgtm.sh
   ```

2. Get the MCP configuration:

   ```sh
   docker exec lgtm cat /etc/lgtm/mcp.json   # or: podman exec ...
   ```

3. Paste the JSON into your AI tool's MCP configuration.

   For Claude Code, you can add the servers individually:

   ```sh
   # Get the service account token
   TOKEN=$(docker exec lgtm cat /tmp/grafana-sa-token)   # or: podman exec ...

   # Add the Grafana MCP server (requires uvx)
   claude mcp add grafana \
     -e GRAFANA_URL=http://localhost:3000 \
     -e GRAFANA_SERVICE_ACCOUNT_TOKEN="$TOKEN" \
     -- uvx mcp-grafana

   # Add the Tempo MCP server
   claude mcp add --transport http tempo http://localhost:3200/api/mcp
   ```

## Backend mapping

| Component  | MCP Server    | Transport | What you can query                  |
|------------|---------------|-----------|-------------------------------------|
| Grafana    | `grafana`     | stdio     | Dashboards, PromQL, LogQL           |
| Tempo      | `tempo`       | HTTP      | Traces via TraceQL                  |

## Collector debug exporter

The OpenTelemetry Collector includes a debug exporter that logs all received
telemetry to stdout. This is useful for verifying that data is flowing correctly.

Enable it by setting the environment variable before starting the container:

```sh
OTEL_COLLECTOR_DEBUG_EXPORTER=true ./run-lgtm.sh
```

This adds the `debug` exporter to the logs, metrics, and traces pipelines.
The output appears in the collector's logs (enable with `ENABLE_LOGS_OTELCOL=true`
or `ENABLE_LOGS_ALL=true`).

## OBI (eBPF auto-instrumentation)

When [OBI is enabled][obi-readme], it generates traces and RED metrics automatically.
These are queryable via PromQL through the Grafana MCP server:

```promql
# Number of instrumented processes
obi_instrumented_processes

# HTTP request duration (RED metrics)
http_server_request_duration_seconds_count{http_route="/rolldice"}
```

See the [OBI section in the README][obi-readme] for setup instructions.

## Pyroscope (continuous profiling)

Pyroscope collects continuous profiles on port 4040. Explore them in Grafana's
**Explore > Profiles** view. There is no MCP integration for Pyroscope yet.

[mcp]: https://modelcontextprotocol.io/
[obi-readme]: ../README.md#enable-obi-ebpf-auto-instrumentation
