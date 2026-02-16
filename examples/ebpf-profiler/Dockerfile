FROM otel/opentelemetry-ebpf-profiler-dev:202601021410@sha256:1d78b71cfc84beafdb321a11375628c2cb8c2d5ca544e34ddf50e3478eff8e6f AS builder

# renovate: datasource=github-tags depName=opentelemetry-ebpf-profiler packageName=open-telemetry/opentelemetry-ebpf-profiler
ARG OPENTELEMETRY_EBPF_PROFILER_VERSION=v0.0.202606
RUN wget https://github.com/open-telemetry/opentelemetry-ebpf-profiler/archive/$OPENTELEMETRY_EBPF_PROFILER_VERSION.tar.gz
RUN mkdir /profiler
RUN tar --strip-components=1 -C /profiler -xzf $OPENTELEMETRY_EBPF_PROFILER_VERSION.tar.gz
WORKDIR /profiler
RUN /bin/bash -euo pipefail -c "source /etc/profile && make ebpf-profiler"

FROM ubuntu:24.04@sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b

COPY --from=builder /profiler/ebpf-profiler /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/ebpf-profiler"]
