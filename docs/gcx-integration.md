# Query and troubleshoot local telemetry with gcx

Run gcx and your coding agent on the host; LGTM remains the backend. Normal
LGTM use and plain gcx queries need neither an agent nor Grafana Cloud.

Use the gcx-owned [diagnostic guide][diagnostics] for installation, existing
skills, safety boundaries, and verification. This page supplies only the local
LGTM connection and example application. Its commands target gcx 1.3.0.

## Start or reuse LGTM

Follow [Run the Docker image](../README.md#run-the-docker-image). Reuse your
existing instance if it is healthy; do not replace containers or delete volumes
to resolve a port conflict. From the host, check:

```sh
curl --fail --silent --show-error http://localhost:3000/api/health
```

Use the actual published Grafana address if it differs. Health is not proof that
the app is exporting telemetry. To reproduce a walkthrough later, record the
image tag/digest, gcx version, and example checkout revision you used.

## Configure an isolated local connection

Follow the [private configuration step][connection] in the shared guide to
create `GCX_DIAGNOSTICS_CONFIG`. Instead of its remote login example, put the
following configuration in that **new private file**, not in an existing user
or repository config:

```yaml
current-context: lgtm-local
stacks:
  lgtm-local:
    grafana:
      server: http://localhost:3000
      org-id: 1
      auth-method: basic
      user: admin
      password: admin
contexts:
  lgtm-local:
    stack: lgtm-local
    datasources:
      prometheus: prometheus
      loki: loki
      tempo: tempo
      pyroscope: pyroscope
```

These credentials are only the disposable image defaults. If you customized
Grafana authentication, enter the actual credentials locally or configure a
read-only service-account token using the shared guide's authentication link.
Do not paste secrets into chat or commit this file. Do not reset Grafana's
credentials to match this example. Review intentional environment overrides so
the request does not accidentally target another instance.

```sh
gcx config check --config "$GCX_DIAGNOSTICS_CONFIG" --context lgtm-local
gcx datasources list --config "$GCX_DIAGNOSTICS_CONFIG" --context lgtm-local
gcx metrics query 'vector(1)' --datasource prometheus \
  --config "$GCX_DIAGNOSTICS_CONFIG" --context lgtm-local
```

The stock datasource UIDs are `prometheus`, `loki`, `tempo`, and `pyroscope`.
If discovery differs, use the returned UIDs in this private config. The
`vector(1)` result verifies querying, not application ingestion. Continue using
`lgtm-local` (rather than the shared guide's example name `diagnostics`).

## Send and find a fresh application trace

Use an already instrumented application you own, or this repository's Python
example. For the example, install Python and its venv support, then run from the
repository root in a separate terminal:

```sh
cd examples/python
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 ./run.sh
```

The script installs dependencies in its local `venv` and starts the instrumented
Flask application on port 8082 with service name `rolldice`. These endpoint
settings apply to this example process only, not another application's exporter.
For containerized applications, `localhost` means that application's container;
use the appropriate network address rather than copying this host-run example.

In your diagnostic terminal, record the start time and send a request:

```sh
date -u +%Y-%m-%dT%H:%M:%SZ
curl --fail http://localhost:8082/rolldice
gcx traces query '{ resource.service.name = "rolldice" }' \
  --datasource tempo --since 5m --limit 10 \
  --config "$GCX_DIAGNOSTICS_CONFIG" --context lgtm-local
```

Allow for asynchronous export and retry the bounded query. Check returned trace
timestamps against the request and inspect a matching trace; old `rolldice`
traffic does not prove this request succeeded. On a shared instance, use a
distinct application identity/request correlation or narrow the query to the
recorded time window. Record a matching fresh trace ID before declaring success.

If the request works but the trace is missing, continue with the shared guide
rather than changing ports, exporter settings, or dashboard filters blindly.

## Investigate your original symptom

After installing the existing gcx skills through the shared guide, start the
agent in your application checkout and supply the private config path and scope:

> This application sends telemetry to my local docker-lgtm instance, but this
> dashboard is empty: `<URL>`. Use gcx with `<private config path>` and context
> `lgtm-local`. Inspect only `<application and container/project names>`.
> Diagnose first. State what you could not observe; do not infer data loss from
> missing access. Ask before changing application, Collector, or dashboard
> configuration, restarting resources, or enabling payload logging.

### Optional Collector receipt evidence

For a new disposable diagnostic instance, the existing options
`OTEL_COLLECTOR_DEBUG_EXPORTER=true` and `ENABLE_LOGS_OTELCOL=true` enable
Collector payload logging. With `run-lgtm.sh`, set `ENABLE_LOGS_OTELCOL=true`
in its `.env` file and pass `OTEL_COLLECTOR_DEBUG_EXPORTER=true` when launching.
With a direct `docker run`, pass both using `-e`. Preserve other `.env` entries
and restore only the settings you changed. Changing an existing instance's
settings requires approval and
may require recreation; do not restart it silently.

This shows evidence at LGTM's Collector boundary, not at a separate upstream
Collector or at final storage. Payloads can contain sensitive data. Disable the
options after investigation and handle captured logs accordingly.

Use the shared guide's [repair verification and cleanup][verification]. Stop the
example process with Ctrl-C; remove its generated venv only if you no longer
need it. Keep pre-existing LGTM instances and data. Clean up a disposable stack
only when its owner confirms it is no longer needed.

[diagnostics]: https://github.com/grafana/gcx/blob/docs/gcx-diagnostics-entry/docs/guides/diagnose-missing-telemetry.md
[connection]: https://github.com/grafana/gcx/blob/docs/gcx-diagnostics-entry/docs/guides/diagnose-missing-telemetry.md#connect-without-changing-your-usual-context
[verification]: https://github.com/grafana/gcx/blob/docs/gcx-diagnostics-entry/docs/guides/diagnose-missing-telemetry.md#verify-a-repair-and-restore-the-environment
