# Blog Post

## Title

Observability in under 5 seconds

## Content

Happy Birthday grafana/otel-lgtm \- 1 year, 1k stars, and a round 0.11.1 as a version number (at the time of writing).

grafana/otel-lgtm is a docker image that contains a complete Open Source OpenTelemetry solution, based on the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/), [Prometheus](https://github.com/prometheus/prometheus), [Loki](https://github.com/grafana/loki/), [Tempo](https://github.com/grafana/tempo/), [Pyroscope](https://github.com/grafana/pyroscope), and [Grafana](https://github.com/grafana/grafana). 

The OpenTelemetry Collector receives OpenTelemetry signals on ports 4317 (gRPC) and 4318 (HTTP). It forwards metrics to a Prometheus database, spans to a Tempo database, logs to a Loki database, and profiles to a Pyroscope database. Grafana has all three databases configured as data sources and exposes its Web UI on port 3000\.

Start the image with docker run \--name lgtm \-p 3000:3000 \-p 4317:4317 \-p 4318:4318 \--rm \-ti [grafana/otel-lgtm](http://docker.io/grafana/otel-lgtm).

You can optionally wait for a log message The OpenTelemetry collector and the Grafana LGTM stack are up and running. (or for the /tmp/ready file) to appear before you start an [OpenTelemtry exporting application](https://opentelemetry.io/docs/zero-code/) (there are also examples in the [repository](https://github.com/grafana/docker-otel-lgtm/tree/main/examples)). 

Finally open Grafana at [http://localhost:3000/](http://localhost:3000/) in a browser to view your traces, logs, profiles, and metrics.

You can read more about using grafana/otel-lgtm in the [announcement blog post](https://grafana.com/blog/2024/03/13/an-opentelemetry-backend-in-a-docker-image-introducing-grafana/otel-lgtm/) from last year.

| *Note*: *The* grafana/otel-lgtm *Docker image is an open source backend for OpenTelemetry that’s intended for development, demo, and testing environments. If you are looking for a production-ready, out-of-the box solution to monitor applications and minimize MTTR with OpenTelemetry and Prometheus, you should try [Grafana Cloud Application Observability](https://grafana.com/products/cloud/application-observability/).* |
| :---- |

### One Year Later

We’re happy to see that grafana/otel-lgtm has made it significantly easier for projects to create a quickstart guide for their observability integrations.

Some of the projects that use grafana/otel-lgtm as their demo observability stack include:

* [Deno](https://docs.deno.com/runtime/fundamentals/open_telemetry/) (Javascript)  
* [Quarkus](https://quarkus.io/guides/observability-devservices-lgtm) (Java)  
* [Bootzooka](https://github.com/softwaremill/bootzooka) (Scala)   
* [Roadster](https://github.com/roadster-rs/roadster) (Rust)   
* [Embrace observability](https://github.com/embrace-io/react-otel-sample/blob/main/backend/grafana.Dockerfile) (Kotlin)


There’s even a [free course from Aalto University in Finland](https://csfoundations.cs.aalto.fi/en/courses/designing-and-building-scalable-web-applications/part-6/3-lgtm-stack) to test your knowledge about observability with a lesson about the LGTM stack.

We were building the project for testing related uses such as [testcontainers](https://testcontainers.com/modules/grafana/) originally, but we were amazed to find out that the ease of use inspired some users to run their [production setup](https://github.com/grafana/docker-otel-lgtm/discussions/127) with grafana/otel-lgtm as well. 

All of that wouldn’t have been possible without your help. A big thank you goes to the contributions of the [Node.js example](https://github.com/grafana/docker-otel-lgtm/pull/284), [support for PowerShell](https://github.com/grafana/docker-otel-lgtm/pull/275), [publishing on the GitHub registry](https://github.com/grafana/docker-otel-lgtm/pull/160), and all the other contributions during the first year\!

| *Note*: We also created a [OATs](https://github.com/grafana/oats), a no-code test framework based on grafana/otel-lgtm where you can test your application using YAML (which we use to test this image as well): expected:   traces:     \- traceql: '{ span.http.route \= "/rolldice/{player?}" }'       spans:         \- name: "GET /rolldice/{player?}"            attributes:             otel.library.name: Microsoft.AspNetCore  |
| :---- |

### What’s new

The most requested feature was to reduce the startup speed, which directly translates to faster tests, e.g. for [testcontainers](https://testcontainers.com/modules/grafana/).   
Thus we reduced the startup time from around 60s [earlier this year](https://github.com/grafana/docker-otel-lgtm/releases/tag/v0.8.6) to **under 5 seconds** now.

In addition, we added an option to [send the telemetry signals also to an external host](https://github.com/grafana/docker-otel-lgtm/?tab=readme-ov-file#send-data-to-vendors). For example, this allows you to view the same data in [*Grafana Cloud Application Observability*](https://grafana.com/products/cloud/application-observability/) or any other vendor that can receive OTLP (the OTel data protocol). 

Lastly, we recently added [Grafana Pyroscope](https://github.com/grafana/pyroscope) to support the latest telemetry signal \- which is profiling.

#### Improved startup time

The startup time is the time until the health checks of all components (databases, OTel Collector, Grafana) are ready, which you can see from the OpenTelemetry collector and the Grafana LGTM stack are up and running. log message.

The most obvious improvement was to [reduce the scrape interval of the Prometheus-based health check](https://github.com/grafana/docker-otel-lgtm/pull/392/files#diff-6db5e34a1aaf1f6abe4cbb9be70e8267e04d36057acf2a0d6fcc7d4435ea5e15R12) in the OTel Collector from the default value of 1 minute to 1 second, which was responsible for an average start time of 30 seconds. It turned out that it was even faster to use the [health check extension](https://github.com/grafana/docker-otel-lgtm/blob/c123e530a46a11e7a1522bd7bd5e5aec3dbc529c/docker/otelcol-config.yaml#L19-L22) than waiting for a metric to arrive in Prometheus.

The databases also have configuration parameters for [DNS lookup](https://github.com/grafana/docker-otel-lgtm/blob/0bee7514254fb8eafe0ab6c8e3db03c2c928c527/docker/loki-config.yaml#L40) and for how long they [should be ready](https://github.com/grafana/docker-otel-lgtm/blob/0bee7514254fb8eafe0ab6c8e3db03c2c928c527/docker/loki-config.yaml#L37) to serve requests, which are all tailored for long-living processes where startup time is not a concern.

Thankfully, all databases give a specific reason (in their health check endpoint) why they are not yet ready, so you don’t have to guess from reading the source code.

#### Welcome Grafana Pyroscope

![][image2]

Profiling is the latest telemetry signal in OTel, which you can see in the [OTel matrix](https://opentelemetry.io/status/) \- it’s not even been added to the table at the time of writing.

Nevertheless, there is active development in at least some programming languages \- and there is a development version of the [eBPF profiler](https://github.com/open-telemetry/opentelemetry-ebpf-profiler), which can send data in OTLP format. Thus we decided to add [Grafana Pyroscope](https://github.com/grafana/pyroscope) as the fourth database \- so you can easily follow the improvements to come.

The screenshot above is taken from the [eBPF profiler example](https://github.com/grafana/docker-otel-lgtm/tree/main/examples/ebpf-profiler) (which uses the [Go example](https://github.com/grafana/docker-otel-lgtm/tree/main/examples/go)) \- which is the only setup we were able to get running reliably. It shows a [busy waiting](https://github.com/grafana/docker-otel-lgtm/blob/main/examples/go/rolldice.go#L29-L34) function that would be harder to detect using tracing unless you created a span around the roll method manually. Eventually, you should be able to seamlessly blend traces and profiles to optimize your critical path in a microservice environment.

To run the eBPF profiler example:

1. cd examples/ebpf-profiler  
2. docker compose up \--remove-orphans \--build  
3. Go to [Drilldown Profiles](http://localhost:3000/a/grafana-pyroscope-app/explore?searchText=&panelType=time-series&layout=grid&hideNoData=off&explorationType=flame-graph&var-serviceName=unknown&var-profileMetricId=process_cpu:cpu:nanoseconds:cpu:nanoseconds&var-spanSelector=undefined&var-dataSource=pyroscope&var-filters=&var-filtersBaseline=&var-filtersComparison=&var-groupBy=all&maxNodes=16384)   
4. You can select any application running inside docker compose and your host system \- because eBPF is a kernel-level technology  
5. Let’s look at the included Go application  
   1. In “Filter by label values”, select “process\_executable\_name”, then “=”, then “rolldice”  
   2. Click on “Flame Graph” in the bottom half to make more room for finding what is slow

Here at Grafana Labs, we’re [fully committed to the OpenTelemetry project](https://grafana.com/blog/2024/01/31/opentelemetry-and-grafana-labs-whats-new-and-whats-next/) and community. We continually focus on building compatibility into both our open source projects and products, and on helping our users combine OpenTelemetry and Grafana to advance their observability strategies. 

Try out [grafana/docker-otel-lgtm](https://github.com/grafana/docker-otel-lgtm/) today\!
