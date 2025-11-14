FROM otel/opentelemetry-ebpf-profiler-dev:202508261505@sha256:6ab9b5ff6c2a457be97a389887caf9f3cd5344f760fdab0101b9965236bbb2db AS builder

# renovate: datasource=github-tags depName=opentelemetry-ebpf-profiler packageName=open-telemetry/opentelemetry-ebpf-profiler
ARG VERSION=7cdeb21f984fd0e003bc6ad07a9057a3f3c1f4da
RUN wget https://github.com/open-telemetry/opentelemetry-ebpf-profiler/archive/$VERSION.tar.gz
RUN mkdir /profiler
RUN tar --strip-components=1 -C /profiler -xzf $VERSION.tar.gz
WORKDIR /profiler
RUN /bin/bash -euo pipefail -c "source /etc/profile && make ebpf-profiler"

FROM ubuntu:24.04@sha256:e96e81f410a9f9cae717e6cdd88cc2a499700ff0bb5061876ad24377fcc517d7

RUN apt-get update && \
    apt-get install -y linux-headers-generic && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /profiler/ebpf-profiler /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/ebpf-profiler"]
