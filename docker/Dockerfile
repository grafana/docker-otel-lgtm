FROM redhat/ubi8

ENV GRAFANA_VERSION="10.2.0"
ENV PROMETHEUS_VERSION="2.47.2"
ENV TEMPO_VERSION="2.3.0"
ENV LOKI_VERSION="2.9.2"
ENV OPENTELEMETRY_COLLECTOR_VERSION="0.88.0"

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

RUN yum install -y unzip jq

RUN curl -sOL https://dl.grafana.com/oss/release/grafana-$GRAFANA_VERSION.linux-amd64.tar.gz && \
    tar xfz grafana-$GRAFANA_VERSION.linux-amd64.tar.gz && \
    rm grafana-$GRAFANA_VERSION.linux-amd64.tar.gz

RUN curl -sOL https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz && \
    tar xfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz && \
    mv prometheus-$PROMETHEUS_VERSION.linux-amd64 prometheus-$PROMETHEUS_VERSION && \
    rm prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz

RUN curl -sOL https://github.com/grafana/tempo/releases/download/v$TEMPO_VERSION/tempo_${TEMPO_VERSION}_linux_amd64.tar.gz && \
    mkdir tempo-$TEMPO_VERSION/ && \
    tar xfz tempo_${TEMPO_VERSION}_linux_amd64.tar.gz -C tempo-$TEMPO_VERSION/ && \
    rm tempo_${TEMPO_VERSION}_linux_amd64.tar.gz

RUN curl -sOL https://github.com/grafana/loki/releases/download/v$LOKI_VERSION/loki-linux-amd64.zip && \
    mkdir loki-$LOKI_VERSION && \
    unzip loki-linux-amd64 -d loki-$LOKI_VERSION/ && \
    rm loki-linux-amd64.zip

RUN curl -sOL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$OPENTELEMETRY_COLLECTOR_VERSION/otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_amd64.tar.gz && \
    mkdir otelcol-contrib-$OPENTELEMETRY_COLLECTOR_VERSION && \
    tar xfz otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_amd64.tar.gz -C otelcol-contrib-$OPENTELEMETRY_COLLECTOR_VERSION/ && \
    rm otelcol-contrib_${OPENTELEMETRY_COLLECTOR_VERSION}_linux_amd64.tar.gz

COPY prometheus.yaml .
COPY run-prometheus.sh .
COPY grafana-datasources.yaml ./grafana-$GRAFANA_VERSION/conf/provisioning/datasources/
COPY grafana-dashboards.yaml grafana-$GRAFANA_VERSION/conf/provisioning/dashboards/
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

CMD ./run-all.sh
