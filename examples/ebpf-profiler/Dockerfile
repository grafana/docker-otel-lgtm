FROM otel/opentelemetry-ebpf-profiler-dev:202601021410@sha256:1d78b71cfc84beafdb321a11375628c2cb8c2d5ca544e34ddf50e3478eff8e6f AS builder

# renovate: datasource=github-tags depName=opentelemetry-ebpf-profiler packageName=open-telemetry/opentelemetry-ebpf-profiler
ARG OPENTELEMETRY_EBPF_PROFILER_VERSION=v0.0.202645
RUN wget --progress=dot:giga https://github.com/open-telemetry/opentelemetry-ebpf-profiler/archive/$OPENTELEMETRY_EBPF_PROFILER_VERSION.tar.gz && \
    mkdir /profiler && \
    tar --strip-components=1 -C /profiler -xzf $OPENTELEMETRY_EBPF_PROFILER_VERSION.tar.gz
WORKDIR /profiler
RUN /bin/bash -euo pipefail -c "source /etc/profile && make otelcol-ebpf-profiler"

FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db

COPY --from=builder /profiler/otelcol-ebpf-profiler /usr/local/bin/
COPY otelcol-config.yaml /etc/otelcol-ebpf-profiler/config.yaml

ENTRYPOINT ["/usr/local/bin/otelcol-ebpf-profiler"]
CMD ["--config", "/etc/otelcol-ebpf-profiler/config.yaml", "--feature-gates=+service.profilesSupport"]
