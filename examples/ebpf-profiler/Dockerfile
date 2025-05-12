FROM ubuntu:24.04 AS builder

ENV GO_VERSION=1.24.3
ARG VERSION=4377c7485ec426eb1210098593e6175d2d53bcd8

RUN apt-get update && apt-get -y install wget gcc
RUN wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
RUN wget https://github.com/open-telemetry/opentelemetry-ebpf-profiler/archive/$VERSION.tar.gz
RUN mkdir /profiler
RUN tar --strip-components=1 -C /profiler -xzf $VERSION.tar.gz
WORKDIR /profiler
RUN /usr/local/go/bin/go build .

FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y linux-headers-generic && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /profiler/ebpf-profiler /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/ebpf-profiler"]

