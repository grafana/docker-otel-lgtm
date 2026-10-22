# OpenTelemetry eBPF profiler examples

**⚠️ Important: Early access**
The OpenTelemetry eBPF profiler is under active development and may change in the future.
This example is based on the latest Git commit - releases no not yet exist.

**⚠️ Important: Linux-only Support**
This example can only be run on Linux systems (amd64/arm64) as it relies on eBPF technology which is
specific to the Linux kernel.
The profiler requires privileged access to system resources.
For more details refer to the OpenTelemetry ebpf profiler
[docs](https://github.com/open-telemetry/opentelemetry-ebpf-profiler).

These examples demonstrate:

1. OpenTelemetry eBPF profiler collecting system-wide profiles
2. OpenTelemetry Collector receiving and processing the data from the profiler
3. Pyroscope receiving and visualizing the profiles via Grafana

## Docker example

1. Start the environment:

```bash
# Start all services
docker compose up --remove-orphans --build

# To clean up
docker compose down
```

1. Access the UI:

Navigate to the [Pyroscope UI][Pyroscope UI] to visualize the profiles.

## Example output

![Image](https://github.com/user-attachments/assets/15ff58d4-218a-43dd-9835-df12e13ced3f)

## Troubleshooting missing profiles

Check the path from the profiler to Pyroscope one step at a time:

1. Confirm the example application is running and receiving requests. The profiler collects system-wide CPU
   samples, so a quiet application may not produce samples for the function you expect.
2. Inspect the Collector and Pyroscope logs while the example is running:

   ```bash
   docker compose logs --follow lgtm otel-ebpf-profiler
   ```

   This example's Compose file enables `ENABLE_LOGS_OTELCOL` and `ENABLE_LOGS_PYROSCOPE`. Other LGTM
   launches suppress service logs by default; enable the relevant `ENABLE_LOGS_*` setting when starting a
   disposable diagnostic instance. See [optional Collector receipt evidence][collector-receipt] before enabling
   payload logging; payloads can contain sensitive data.
3. Check whether profiles reach the Collector and whether its profile exporter can send them. The bundled
   Prometheus is available at `http://localhost:9090`; for example, query these Collector counters:

   ```bash
   curl -fsS -G --data-urlencode 'query=otelcol_receiver_accepted_profile_samples{receiver="otlp"}' \
     http://localhost:9090/api/v1/query
   curl -fsS -G --data-urlencode 'query=otelcol_exporter_sent_profile_samples{exporter="otlp_grpc/profiles"}' \
     http://localhost:9090/api/v1/query
   curl -fsS -G --data-urlencode 'query=otelcol_exporter_send_failed_profile_samples{exporter="otlp_grpc/profiles"}' \
     http://localhost:9090/api/v1/query
   ```

   Give Prometheus at least one scrape interval before interpreting the results; the bundled Collector scrape
   interval is one second. If a query has no series, check the scrape target at `http://localhost:9090/targets`
   before treating that as zero samples. Counters are cumulative for the running Collector. An increase in
   `accepted` confirms samples entered its pipeline; it does not confirm Pyroscope stored them. If `sent` does
   not increase while `send_failed` does, inspect the Collector and Pyroscope logs for the receiver-side error.
   If the counters are present but do not increase, investigate the profiler, its permissions, and whether the
   application is generating samples first.
4. If Pyroscope reports an invalid profile or label (for example, an empty label name), check compatibility
   between the Collector's OTLP Profiles output and the Pyroscope receiver version before attributing the
   failure to profiler sampling or symbolization. Collector acceptance alone only confirms the upstream hop.

[collector-receipt]: ../../docs/gcx-integration.md#optional-collector-receipt-evidence

[Pyroscope UI]: http://127.0.0.1:3000/a/grafana-pyroscope-app/explore?searchText=&panelType=time-series&layout=grid&hideNoData=off&explorationType=flame-graph&var-serviceName=unknown&var-profileMetricId=process_cpu:cpu:nanoseconds:cpu:nanoseconds&var-spanSelector=undefined&var-dataSource=pyroscope&var-filters=&var-filtersBaseline=&var-filtersComparison=&var-groupBy=all&maxNodes=16384
