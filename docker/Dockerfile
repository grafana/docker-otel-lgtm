FROM redhat/ubi8

ENV GRAFANA_VERSION="11.1.3"
ENV PROMETHEUS_VERSION="2.53.1"
ENV TEMPO_VERSION="2.5.0"
ENV LOKI_VERSION="3.1.0"
ENV OPENTELEMETRY_COLLECTOR_VERSION="0.105.0"

# TARGETARCH is automatically detected and set by the Docker daemon during the build process. If the build starts
# on an amd64 architecture, than the TARGETARCH will be set to `amd64`.
# More details on the variables can be found here: https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

RUN yum install -y unzip jq procps

RUN curl -sOL https://dl.grafana.com/oss/release/grafana-$GRAFANA_VERSION.linux-${TARGETARCH}.tar.gz && \
    tar xfz grafana-$GRAFANA_VERSION.linux-${TARGETARCH}.tar.gz && \
    rm grafana-$GRAFANA_VERSION.linux-${TARGETARCH}.tar.gz && \
    mv grafana-v$GRAFANA_VERSION grafana/

RUN curl -sOL https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-${TARGETARCH}.tar.gz && \
    tar xfz prometheus-$PROMETHEUS_VERSION.linux-${TARGETARCH}.tar.gz && \
    mv prometheus-$PROMETHEUS_VERSION.linux-${TARGETARCH} prometheus && \
    rm prometheus-$PROMETHEUS_VERSION.linux-${TARGETARCH}.tar.gz

RUN curl -sOL https://github.com/grafana/tempo/releases/download/v$TEMPO_VERSION/tempo_${TEMPO_VERSION}_linux_${TARGETARCH}.tar.gz && \
    mkdir tempo && \
    tar xfz tempo_${TEMPO_VERSION}_linux_${TARGETARCH}.tar.gz -C tempo/ && \
    rm tempo_${TEMPO_VERSION}_linux_${TARGETARCH}.tar.gz

RUN curl -sOL https://github.com/grafana/loki/releases/download/v$LOKI_VERSION/loki-linux-${TARGETARCH}.zip && \
    mkdir loki && \
    unzip loki-linux-${TARGETARCH} -d loki/ && \
    rm loki-linux-${TARGETARCH}.zip

RUN curl -sOL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$OPENTELEMETRY_COLLECTOR_VERSION/otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_${TARGETARCH}.tar.gz && \
    mkdir otelcol-contrib && \
    tar xfz otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_${TARGETARCH}.tar.gz -C otelcol-contrib/ && \
    rm otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_${TARGETARCH}.tar.gz

COPY prometheus.yaml .
COPY run-prometheus.sh .
COPY grafana-datasources.yaml ./grafana/conf/provisioning/datasources/
COPY grafana-dashboards.yaml ./grafana/conf/provisioning/dashboards/
COPY grafana-dashboard-red-metrics-classic.json .
COPY grafana-dashboard-red-metrics-native.json .
COPY grafana-dashboard-jvm-metrics.json .
COPY run-grafana.sh .
COPY loki-config.yaml .
COPY run-loki.sh .
COPY tempo-config.yaml .
COPY run-tempo.sh .
COPY otelcol-config.yaml .
COPY run-otelcol.sh .
COPY run-all.sh .

CMD /otel-lgtm/run-all.sh
