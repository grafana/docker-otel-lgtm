# Blog Post

## Title

Observability in Under 5 Seconds: grafana/otel-lgtm turns 1 year old!

## Content

Happy Birthday to `grafana/otel-lgtm`! Over the past year, it has achieved 1k stars, celebrated version 0.11.1, and made observability just one docker command away.

`grafana/otel-lgtm` is a Docker image that provides a complete Open Source OpenTelemetry solution. It integrates the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/), [Prometheus](https://github.com/prometheus/prometheus), [Loki](https://github.com/grafana/loki/), [Tempo](https://github.com/grafana/tempo/), [Pyroscope](https://github.com/grafana/pyroscope), and [Grafana](https://github.com/grafana/grafana).

### Quickstart

The OpenTelemetry Collector receives signals on ports 4317 (gRPC) and 4318 (HTTP). It forwards:
- Metrics to Prometheus
- Traces to Tempo
- Logs to Loki
- Profiles to Pyroscope

Grafana is pre-configured with these data sources and exposes its Web UI on port 3000.

To get started, run:

```bash
docker run --name lgtm -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm
```

Wait for the log message `The OpenTelemetry collector and the Grafana LGTM stack are up and running.` or check for the `/tmp/ready` file - which will appear in a couple of seconds. Then, start your [OpenTelemetry-exporting application](https://opentelemetry.io/docs/zero-code/). Examples are available in the [repository](https://github.com/grafana/docker-otel-lgtm/tree/main/examples).

Finally, open [http://localhost:3000/](http://localhost:3000/) in your browser to view traces, logs, profiles, and metrics.

> *Note*: The `grafana/otel-lgtm` Docker image is designed for development, demo, and testing environments. For production-ready observability, consider [Grafana Cloud Application Observability](https://grafana.com/products/cloud/application-observability/).

### One Year Later

`grafana/otel-lgtm` has made it easier for projects to create a demo setup for observability. Some notable adopters include:

- [Deno](https://docs.deno.com/runtime/fundamentals/open_telemetry/) (JavaScript)
- [Quarkus](https://quarkus.io/guides/observability-devservices-lgtm) (Java)
- [Bootzooka](https://github.com/softwaremill/bootzooka) (Scala)
- [Roadster](https://github.com/roadster-rs/roadster) (Rust)
- [Embrace Observability](https://github.com/embrace-io/react-otel-sample/blob/main/backend/grafana.Dockerfile) (Kotlin)

Even a [free course from Aalto University](https://csfoundations.cs.aalto.fi/en/courses/designing-and-building-scalable-web-applications/part-6/3-lgtm-stack) includes lessons on the LGTM stack.

A big thank you to the community for contributions like:
- [Node.js example](https://github.com/grafana/docker-otel-lgtm/pull/284)
- [PowerShell support](https://github.com/grafana/docker-otel-lgtm/pull/275)
- [Publishing on GitHub Registry](https://github.com/grafana/docker-otel-lgtm/pull/160)
      
> *Note*: We also created [OATs](https://github.com/grafana/oats), 
> a no-code test framework based on grafana/otel-lgtm where you can test your application using YAML 
> (which we use to test this image as well): 
> ```
> expected:   
>   traces:     
>     - traceql: '{ span.http.route \= "/rolldice/{player?}" }'       
>       spans:         
>         - name: "GET /rolldice/{player?}"            
>           attributes:             
>             otel.library.name: Microsoft.AspNetCore

### What’s New

#### Faster Startup Time

The most requested feature was faster startup. We reduced the startup time from ~60 seconds to **under 5 seconds**. Key improvements include:
- Reducing the Prometheus health check scrape interval from 1 minute to 1 second.
- Using the [health check extension](https://github.com/grafana/docker-otel-lgtm/blob/main/docker/otelcol-config.yaml) for faster readiness detection.
- Optimizing database configurations for DNS lookups and readiness.

These changes are optimized for fast startup, not for high scalability.

#### Grafana Pyroscope Integration

Profiling is the latest OpenTelemetry signal, and we’ve added [Grafana Pyroscope](https://github.com/grafana/pyroscope) as the fourth database. This allows you to seamlessly blend traces and profiles to optimize your critical paths.

To try the [eBPF profiler example](https://github.com/grafana/docker-otel-lgtm/tree/main/examples/ebpf-profiler):
1. Navigate to the example directory: `cd examples/ebpf-profiler`
2. Start the stack: `docker compose up --remove-orphans --build`
3. Open [Drilldown Profiles](http://localhost:3000/a/grafana-pyroscope-app/explore) in Grafana.
4. Filter by `process_executable_name = rolldice` and explore the Flame Graph.

### Conclusion

Here at Grafana Labs, we’re [fully committed to the OpenTelemetry project](https://grafana.com/blog/2024/01/31/opentelemetry-and-grafana-labs-whats-new-and-whats-next/) and community. We continually focus on building compatibility into both our open source projects and products, and on helping our users combine OpenTelemetry and Grafana to advance their observability strategies. 

Try out [grafana/docker-otel-lgtm](https://github.com/grafana/docker-otel-lgtm/) today!
