# Run lgtm with Nomad (and Consul)

This directory contains a Nomad job that runs the `grafana/otel-lgtm` image,
mirroring the ports used by [`run-lgtm.sh`](../run-lgtm.sh) and
[`k8s/lgtm.yaml`](../k8s/lgtm.yaml).

> [!IMPORTANT]
> Intended for development, demo, and testing only — not for production.

## Prerequisites

- [Nomad](https://developer.hashicorp.com/nomad) with the Docker task driver
- Optional but recommended: [Consul](https://developer.hashicorp.com/consul) for
  the job's `service` blocks (`provider = "consul"`)

## Deploy

```sh
nomad job run nomad/lgtm.nomad.hcl
```

Override the image tag if needed:

```sh
nomad job run -var="image=docker.io/grafana/otel-lgtm:0.32.0" nomad/lgtm.nomad.hcl
```

## Access

| Service    | URL / address           |
|------------|-------------------------|
| Grafana    | `http://127.0.0.1:3000` |
| OTLP gRPC  | `127.0.0.1:4317`        |
| OTLP HTTP  | `http://127.0.0.1:4318` |
| Prometheus | `http://127.0.0.1:9090` |
| Tempo      | `http://127.0.0.1:3200` |
| Pyroscope  | `http://127.0.0.1:4040` |

Default Grafana credentials: `admin` / `admin`.

If Consul is enabled, services are registered as `lgtm-grafana`,
`lgtm-otel-http`, `lgtm-otel-grpc`, and `lgtm-prometheus`.

## Persistence

The job uses Nomad `ephemeral_disk` (similar to Kubernetes `emptyDir`). Data is
kept for the life of the allocation. For durable host paths, add Nomad
`host_volume` mounts for `/data/grafana`, `/data/prometheus`, `/data/loki`,
`/data/tempo`, and `/data/pyroscope` (see `run-lgtm.sh` volume layout).

## Without Consul

If you are not running Consul, change each `service` block's `provider` to
`"nomad"` (Nomad native service discovery) or remove the `service` blocks.
