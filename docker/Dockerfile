ARG LGTM_VERSION=development
# renovate: datasource=github-releases depName=grafana packageName=grafana/grafana
ARG GRAFANA_VERSION=v13.0.1
# renovate: datasource=github-releases depName=prometheus packageName=prometheus/prometheus
ARG PROMETHEUS_VERSION=v3.11.2
# renovate: datasource=github-releases depName=tempo packageName=grafana/tempo
ARG TEMPO_VERSION=v2.10.5
# renovate: datasource=github-releases depName=loki packageName=grafana/loki
ARG LOKI_VERSION=v3.7.1
# renovate: datasource=github-releases depName=pyroscope packageName=grafana/pyroscope
ARG PYROSCOPE_VERSION=v2.0.1
# renovate: datasource=github-releases depName=opentelemetry-collector packageName=open-telemetry/opentelemetry-collector-releases
ARG OPENTELEMETRY_COLLECTOR_VERSION=v0.150.1
# renovate: datasource=github-releases depName=obi packageName=open-telemetry/opentelemetry-ebpf-instrumentation
ARG OBI_VERSION=v0.8.0

# This is a source-only stage, so collapsing it into neighboring stages is not useful.
# hadolint global ignore=DL3059
FROM docker.io/otel/ebpf-instrument:${OBI_VERSION} AS obi-source

# Download and extract components on the build platform (no QEMU) to avoid tar/rpm
# failures that occur under QEMU emulation with overlayfs. The download scripts use
# TARGETARCH to fetch the correct platform-specific archives.
FROM --platform=$BUILDPLATFORM docker.io/redhat/ubi9:9.7@sha256:fd3612ebe7968002122fb8c41df2cf9bd3f9916c573f7248113cdec1d6f4c245 AS downloader

RUN mkdir /otel-lgtm

# UBI repository metadata does not expose stable package versions for these helper tools.
# hadolint ignore=DL3033
RUN yum install -y unzip jq && yum clean all

COPY common.sh \
 detect-arch.sh \
 download-grafana.sh \
 download-prometheus.sh \
 download-tempo.sh \
 download-loki.sh \
 download-pyroscope.sh \
 download-otelcol.sh \
 install-cosign.sh \
 /

# TARGETARCH is automatically detected and set by the Docker daemon during the build process. If the build starts
# on an amd64 architecture, then the TARGETARCH will be set to `amd64`.
# More details on the variables can be found here: https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# renovate: datasource=github-releases depName=cosign packageName=sigstore/cosign
ARG COSIGN_VERSION=v3.0.6

RUN ./install-cosign.sh $COSIGN_VERSION

ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG PYROSCOPE_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION

RUN ./download-grafana.sh $GRAFANA_VERSION && \
    ./download-prometheus.sh $PROMETHEUS_VERSION && \
    ./download-tempo.sh $TEMPO_VERSION && \
    ./download-loki.sh $LOKI_VERSION && \
    ./download-pyroscope.sh $PYROSCOPE_VERSION && \
    ./download-otelcol.sh $OPENTELEMETRY_COLLECTOR_VERSION

FROM docker.io/redhat/ubi9:9.7@sha256:fd3612ebe7968002122fb8c41df2cf9bd3f9916c573f7248113cdec1d6f4c245 AS builder

RUN mkdir /otel-lgtm

COPY common.sh \
 prometheus.yaml \
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

# UBI repository metadata does not expose a stable package version for this build helper.
# hadolint ignore=DL3033
RUN yum install -y dos2unix && yum clean all

# installs for the final image
# see https://github.com/thomasdarimont/keycloak/blob/main/docs/guides/server/containers.adoc#installing-additional-rpm-packages
# Use tsflags=noscripts to skip RPM scriptlets that need /bin/sh inside the installroot,
# which fails under QEMU emulation (arm64 cross-build). CA certs come from the builder image.
RUN mkdir -p /mnt/rootfs
# UBI repository metadata does not expose a stable package version for curl-minimal.
# hadolint ignore=DL3041
RUN dnf install --installroot /mnt/rootfs curl-minimal --releasever 9 --setopt install_weak_deps=false --setopt tsflags=noscripts --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

RUN find /otel-lgtm/ -maxdepth 1 -type f -exec dos2unix {} +

COPY --from=downloader /otel-lgtm/ /otel-lgtm/
COPY --from=obi-source /obi /otel-lgtm/obi/obi

COPY grafana-datasources.yaml /otel-lgtm/grafana/conf/provisioning/datasources/
COPY grafana-dashboards.yaml /otel-lgtm/grafana/conf/provisioning/dashboards/

FROM docker.io/redhat/ubi9-micro:9.7@sha256:2173487b3b72b1a7b11edc908e9bbf1726f9df46a4f78fd6d19a2bab0a701f38

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

# Make the healthcheck script executable.
COPY healthcheck.sh /otel-lgtm/docker/healthcheck.sh
RUN chmod +x /otel-lgtm/docker/healthcheck.sh
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD [ "/otel-lgtm/docker/healthcheck.sh" ]

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
