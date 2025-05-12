# OpenTelemetry eBPF profiler examples

**⚠️ Important: Early access**
The OpenTelemetry eBPF profiler is under active development and may change in the future.
This example is based on the latest git commit - releases no not yet exist.

**⚠️ Important: Linux-only Support**
This example can only be run on Linux systems (amd64/arm64) as it relies on eBPF technology which is specific to the Linux kernel. The profiler requires privileged access to system resources.
For more details refer to the OpenTelemetry ebpf profiler [docs](https://github.com/open-telemetry/opentelemetry-ebpf-profiler).

These examples demonstrate:

1. OpenTelemetry eBPF profiler collecting system-wide profiles
2. OpenTelemetry Collector receiving and processing the data from the profiler
3. Pyroscope receiving and visualizing the profiles via Grafana

## Docker example

1. Start the environment:

```bash
# Start all services
docker compose up --build

# To clean up
docker compose down
```

2. Access the UI:

```bash
# Access Grafana
http://localhost:3000
```

## Example output

![Image](https://github.com/user-attachments/assets/15ff58d4-218a-43dd-9835-df12e13ced3f)
