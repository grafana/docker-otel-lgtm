# renovate: datasource=github-releases depName=grafana packageName=grafana/grafana
ARG GRAFANA_VERSION=v11.6.0
# renovate: datasource=github-releases depName=prometheus packageName=prometheus/prometheus
ARG PROMETHEUS_VERSION=v3.2.1
# renovate: datasource=github-releases depName=tempo packageName=grafana/tempo
ARG TEMPO_VERSION=v2.7.2
# renovate: datasource=github-releases depName=loki packageName=grafana/loki
ARG LOKI_VERSION=v3.4.3
# renovate: datasource=github-releases depName=opentelemetry-collector packageName=open-telemetry/opentelemetry-collector-releases
ARG OPENTELEMETRY_COLLECTOR_VERSION=v0.123.1

# hadolint global ignore=DL3059
FROM redhat/ubi9:9.5-1742918310 AS builder

ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION

# TARGETARCH is automatically detected and set by the Docker daemon during the build process. If the build starts
# on an amd64 architecture, than the TARGETARCH will be set to `amd64`.
# More details on the variables can be found here: https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# hadolint ignore=DL3033
RUN yum install -y unzip

RUN bash -c 'ARCHIVE=grafana-"${GRAFANA_VERSION:1}".linux-"${TARGETARCH}".tar.gz && \
    curl -sOL https://dl.grafana.com/oss/release/"${ARCHIVE}" && \
    tar xfz "${ARCHIVE}" && \
    mv grafana-"${GRAFANA_VERSION}" grafana/'

RUN bash -c 'ARCHIVE=prometheus-"${PROMETHEUS_VERSION:1}".linux-"${TARGETARCH}" && \
    curl -sOL https://github.com/prometheus/prometheus/releases/download/"${PROMETHEUS_VERSION}"/"${ARCHIVE}".tar.gz && \
    tar xfz "${ARCHIVE}".tar.gz && \
    mv "${ARCHIVE}" prometheus'

RUN bash -c 'ARCHIVE=tempo_"${TEMPO_VERSION:1}"_linux_"${TARGETARCH}".tar.gz && \
    curl -sOL https://github.com/grafana/tempo/releases/download/"${TEMPO_VERSION}"/"${ARCHIVE}" && \
    mkdir tempo && \
    tar xfz "${ARCHIVE}" -C tempo/'

RUN bash -c 'ARCHIVE=loki-linux-"${TARGETARCH}".zip && \
    curl -sOL https://github.com/grafana/loki/releases/download/"${LOKI_VERSION}"/"${ARCHIVE}" && \
    mkdir loki && \
    unzip "${ARCHIVE}" -d loki/'

RUN bash -c 'ARCHIVE=otelcol-contrib_"${OPENTELEMETRY_COLLECTOR_VERSION:1}"_linux_"${TARGETARCH}".tar.gz && \
    curl -sOL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/"${OPENTELEMETRY_COLLECTOR_VERSION}"/"${ARCHIVE}" && \
    mkdir otelcol-contrib && \
    tar xfz "${ARCHIVE}" -C otelcol-contrib/'

FROM redhat/ubi9-minimal:9.5-1742914212

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

# hadolint ignore=DL3033
RUN microdnf install -y jq procps dos2unix findutils && microdnf clean all

COPY --from=builder /grafana /grafana
COPY --from=builder /prometheus /prometheus
COPY --from=builder /tempo /tempo
COPY --from=builder /loki /loki
COPY --from=builder /otelcol-contrib /otelcol-contrib

COPY prometheus.yaml .
COPY run-prometheus.sh .
COPY grafana-datasources.yaml ./grafana/conf/provisioning/datasources/
COPY grafana-dashboards.yaml ./grafana/conf/provisioning/dashboards/
COPY grafana-dashboard-red-metrics-classic.json .
COPY grafana-dashboard-red-metrics-native.json .
COPY grafana-dashboard-jvm-metrics.json .
COPY logging.sh .
COPY run-grafana.sh .
COPY loki-config.yaml .
COPY run-loki.sh .
COPY tempo-config.yaml .
COPY run-tempo.sh .
COPY otelcol-config*.yaml .
COPY run-otelcol.sh .
COPY run-all.sh .
# hadolint ignore=SC2038,DL4006
RUN find . -maxdepth 1 -type f | xargs dos2unix

ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION

CMD ["/otel-lgtm/run-all.sh"]
