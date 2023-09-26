FROM redhat/ubi8


RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

RUN yum install -y unzip

RUN curl -sOL https://dl.grafana.com/oss/release/grafana-10.1.2.linux-amd64.tar.gz && \
    tar xfz grafana-10.1.2.linux-amd64.tar.gz && \
    rm grafana-10.1.2.linux-amd64.tar.gz

RUN curl -sOL https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz && \
    tar xfz prometheus-2.47.0.linux-amd64.tar.gz && \
    mv prometheus-2.47.0.linux-amd64 prometheus-2.47.0 && \
    rm prometheus-2.47.0.linux-amd64.tar.gz

RUN curl -sOL https://github.com/grafana/tempo/releases/download/v2.2.3/tempo_2.2.3_linux_amd64.tar.gz && \
    mkdir tempo-2.2.3/ && \
    tar xfz tempo_2.2.3_linux_amd64.tar.gz -C tempo-2.2.3/ && \
    rm tempo_2.2.3_linux_amd64.tar.gz

RUN curl -sOL https://github.com/grafana/loki/releases/download/v2.9.1/loki-linux-amd64.zip && \
    mkdir loki-2.9.1 && \
    unzip loki-linux-amd64 -d loki-2.9.1/ && \
    rm loki-linux-amd64.zip

RUN curl -sOL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.85.0/otelcol-contrib_0.85.0_linux_amd64.tar.gz && \
    mkdir otelcol-contrib-0.85.0 && \
    tar xfz otelcol-contrib_0.85.0_linux_amd64.tar.gz -C otelcol-contrib-0.85.0/ && \
    rm otelcol-contrib_0.85.0_linux_amd64.tar.gz

COPY prometheus.yaml .
COPY run-prometheus.sh .
COPY grafana-datasources.yaml ./grafana-10.1.2/conf/provisioning/datasources/
COPY grafana-dashboards.yaml grafana-10.1.2/conf/provisioning/dashboards/
COPY grafana-dashboard-red-metrics.json .
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
