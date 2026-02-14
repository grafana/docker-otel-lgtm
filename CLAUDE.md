# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

docker-otel-lgtm is an all-in-one OpenTelemetry backend Docker image for
development, demo, and testing. It bundles Grafana, Prometheus, Tempo, Loki,
Pyroscope, and OpenTelemetry Collector into a single container.

## Build & Run Commands

All development tasks use [mise](https://github.com/jdx/mise) as the task
runner. Tool versions (Go, Java, Rust, lychee) are pinned in `mise.toml`.

```bash
# Build Docker image (tag defaults to "latest")
mise run build-lgtm dev1

# Run Docker image
mise run lgtm dev1

# Run locally built image
mise run local-lgtm
```

The build script (`build-lgtm.sh`) auto-detects Docker or Podman.

## Testing

Acceptance tests use [OATS](https://github.com/grafana/oats) (OpenTelemetry
Acceptance Tests). Most examples have an `oats.yaml` that validates traces
(TraceQL), metrics (PromQL), and logs (LogQL).

```bash
# Run all acceptance tests
mise run acceptance-tests

# Run a single example's tests (build first)
mise run build-lgtm dev1
oats -timeout 2h -lgtm-version dev1 examples/nodejs
```

## Linting

```bash
# Auto-fix and verify (recommended dev workflow)
mise run fix

# Verify only (same command used in CI)
mise run lint
```

After running `fix`, always review the changed files before committing —
auto-fixes may produce unexpected results.

Go code uses `.golangci.yaml` config. Markdown uses `.markdownlint.yaml`.
EditorConfig rules in `.editorconfig`.

### Renovate Tracked Deps Linter

`mise run lint` verifies that `.github/renovate-tracked-deps.json` stays in
sync with what Renovate actually tracks. If the snapshot is stale, run
`mise run fix` and commit the result. The lint tasks are provided by
[flint](https://github.com/grafana/flint).

## Architecture

### Docker Image (docker/)

The Dockerfile is a multi-stage build on `redhat/ubi9`. The builder stage
downloads each component via individual `download-*.sh` scripts, using cosign
verification for the OpenTelemetry Collector and SHA256 checksum verification
for other components. Each component has a `run-*.sh` startup script.
`run-all.sh` is the container entrypoint that starts all services.

### Example Applications (examples/)

Language-specific demo apps that emit OpenTelemetry data:
- `examples/java` (port 8080) - Maven + OTel Java Agent
- `examples/go` (port 8081) - Go workspace (`go.work` at repository root)
- `examples/python` (port 8082) - Python + auto-instrumentation
- `examples/dotnet` (port 8083) - .NET/C#
- `examples/nodejs` (port 8084) - Node.js

Most examples have a `docker-compose.oats.yml`, a `run.sh` script, and an
`oats.yaml` for acceptance tests.

### Key Ports

| Service    | Port |
|------------|------|
| Grafana    | 3000 |
| OTLP gRPC  | 4317 |
| OTLP HTTP  | 4318 |
| Pyroscope  | 4040 |
| Prometheus | 9090 |

### OTel Collector Configuration

The collector config is split across `docker/otelcol-config.yaml` (base) and
`docker/otelcol-config-export-http.yaml` (external export). To test the merged
config (run inside the container where the binary is at
`/otel-lgtm/otelcol-contrib/otelcol-contrib`):

```bash
/otel-lgtm/otelcol-contrib/otelcol-contrib \
  --config docker/otelcol-config.yaml \
  --config docker/otelcol-config-export-http.yaml \
  print-initial-config \
  --feature-gates otelcol.printInitialConfig > merged.yaml
```

## Component Versions

All component versions are declared as `ARG` directives in `docker/Dockerfile`
with Renovate annotations for automated dependency updates. Version bumps are
made there, not elsewhere.

## Release Process

Releases are automated weekly (Friday 09:00 UTC) via GitHub Actions if
`docker/` has changed. Version auto-increments based on component changes.
Releases are immutable once published.
