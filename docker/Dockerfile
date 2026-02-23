ARG LGTM_VERSION=development
# renovate: datasource=github-releases depName=grafana packageName=grafana/grafana
ARG GRAFANA_VERSION=v12.3.3
# renovate: datasource=github-releases depName=prometheus packageName=prometheus/prometheus
ARG PROMETHEUS_VERSION=v3.9.1
# renovate: datasource=github-releases depName=tempo packageName=grafana/tempo
ARG TEMPO_VERSION=v2.10.1
# renovate: datasource=github-releases depName=loki packageName=grafana/loki
ARG LOKI_VERSION=v3.6.6
# renovate: datasource=github-releases depName=pyroscope packageName=grafana/pyroscope
ARG PYROSCOPE_VERSION=v1.18.1
# renovate: datasource=github-releases depName=opentelemetry-collector packageName=open-telemetry/opentelemetry-collector-releases
ARG OPENTELEMETRY_COLLECTOR_VERSION=v0.146.1
# renovate: datasource=docker depName=obi packageName=otel/ebpf-instrument
ARG OBI_VERSION=v0.4.1

# hadolint global ignore=DL3059
FROM docker.io/otel/ebpf-instrument:${OBI_VERSION} AS obi-source

# Download and extract components on the build platform (no QEMU) to avoid tar/rpm
# failures that occur under QEMU emulation with overlayfs. The download scripts use
# TARGETARCH to fetch the correct platform-specific archives.
# hadolint ignore=DL3033
FROM --platform=$BUILDPLATFORM docker.io/redhat/ubi9:9.7@sha256:cecb1cde7bda7c8165ae27841c2335667f8a3665a349c0d051329c61660a496c AS downloader

RUN mkdir /otel-lgtm

RUN yum install -y unzip jq

COPY download-grafana.sh \
 download-prometheus.sh \
 download-tempo.sh \
 download-loki.sh \
 download-pyroscope.sh \
 download-otelcol.sh \
 install-cosign.sh \
 ./

# TARGETARCH is automatically detected and set by the Docker daemon during the build process. If the build starts
# on an amd64 architecture, then the TARGETARCH will be set to `amd64`.
# More details on the variables can be found here: https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# renovate: datasource=github-releases depName=cosign packageName=sigstore/cosign
ARG COSIGN_VERSION=v3.0.5

RUN ./install-cosign.sh $COSIGN_VERSION

ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG PYROSCOPE_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION

RUN ./download-grafana.sh $GRAFANA_VERSION
RUN ./download-prometheus.sh $PROMETHEUS_VERSION
RUN ./download-tempo.sh $TEMPO_VERSION
RUN ./download-loki.sh $LOKI_VERSION
RUN ./download-pyroscope.sh $PYROSCOPE_VERSION
RUN ./download-otelcol.sh $OPENTELEMETRY_COLLECTOR_VERSION

FROM docker.io/redhat/ubi9:9.7@sha256:cecb1cde7bda7c8165ae27841c2335667f8a3665a349c0d051329c61660a496c AS builder

RUN mkdir /otel-lgtm

COPY prometheus.yaml \
 run-prometheus.sh \
 grafana-dashboard-red-metrics-classic.json \
 grafana-dashboard-red-metrics-native.json \
 grafana-dashboard-jvm-metrics.json \
 logging.sh \
 run-grafana.sh \
 loki-config.yaml \
 run-loki.sh \
 tempo-config.yaml \
 run-tempo.sh \
 pyroscope-config.yaml \
 run-pyroscope.sh \
 obi-config.yaml \
 run-obi.sh \
 otelcol-config*.yaml \
 run-otelcol.sh \
 run-all.sh \
 /otel-lgtm/

# hadolint ignore=DL3033
RUN yum install -y dos2unix

# installs for the final image
# see https://github.com/thomasdarimont/keycloak/blob/main/docs/guides/server/containers.adoc#installing-additional-rpm-packages
# Use tsflags=noscripts to skip RPM scriptlets that need /bin/sh inside the installroot,
# which fails under QEMU emulation (arm64 cross-build). CA certs come from the builder image.
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl-minimal --releasever 9 --setopt install_weak_deps=false --setopt tsflags=noscripts --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

# hadolint ignore=SC2038,DL4006
RUN find /otel-lgtm/ -maxdepth 1 -type f | xargs dos2unix

COPY --from=downloader /otel-lgtm/ /otel-lgtm/
COPY --from=obi-source /ebpf-instrument /otel-lgtm/obi/obi
COPY --from=obi-source /obi-java-agent.jar /otel-lgtm/obi/obi-java-agent.jar

COPY grafana-datasources.yaml /otel-lgtm/grafana/conf/provisioning/datasources/
COPY grafana-dashboards.yaml /otel-lgtm/grafana/conf/provisioning/dashboards/

FROM docker.io/redhat/ubi9-micro:9.7@sha256:093a704be0eaef9bb52d9bc0219c67ee9db13c2e797da400ddb5d5ae6849fa10

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

COPY --from=builder /mnt/rootfs /
# to send telemetry to an external server
COPY --from=builder /etc/pki /etc/pki

COPY --from=builder /otel-lgtm /otel-lgtm

# just for displaying the version in the startup message
ARG LGTM_VERSION
ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG PYROSCOPE_VERSION
ARG OBI_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION
ENV LGTM_VERSION=${LGTM_VERSION}
ENV GRAFANA_VERSION=${GRAFANA_VERSION}
ENV PROMETHEUS_VERSION=${PROMETHEUS_VERSION}
ENV TEMPO_VERSION=${TEMPO_VERSION}
ENV LOKI_VERSION=${LOKI_VERSION}
ENV PYROSCOPE_VERSION=${PYROSCOPE_VERSION}
ENV OBI_VERSION=${OBI_VERSION}
ENV OPENTELEMETRY_COLLECTOR_VERSION=${OPENTELEMETRY_COLLECTOR_VERSION}

# Re-label the final image, overriding any existing labels from the base image
LABEL description="An open source backend for OpenTelemetry that's intended for development, demo, and testing environments."
LABEL io.k8s.description="An open source backend for OpenTelemetry that's intended for development, demo, and testing environments."
LABEL io.k8s.display-name="Grafana LGTM"
LABEL maintainer="Grafana Labs"
LABEL name="grafana/otel-lgtm"
LABEL org.opencontainers.image.authors="Grafana Labs"
LABEL org.opencontainers.image.documentation="https://github.com/grafana/docker-otel-lgtm/blob/main/README.md"
LABEL org.opencontainers.image.vendor="Grafana Labs"
LABEL org.opencontainers.image.title="Grafana OpenTelemetry LGTM"
LABEL org.opencontainers.image.source="https://github.com/grafana/docker-otel-lgtm"
LABEL summary="An OpenTelemetry backend in a Docker image"
LABEL url="https://github.com/grafana/docker-otel-lgtm"
LABEL vendor="Grafana Labs"

# Blank out labels inherited from the base image that we don't want
LABEL build-date=""
LABEL cpe=""
LABEL io.buildah.version=""
LABEL release=""

CMD ["/otel-lgtm/run-all.sh"]
