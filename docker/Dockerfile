# renovate: datasource=github-releases depName=grafana packageName=grafana/grafana
ARG GRAFANA_VERSION=v11.6.0
# renovate: datasource=github-releases depName=prometheus packageName=prometheus/prometheus
ARG PROMETHEUS_VERSION=v3.2.1
# renovate: datasource=github-releases depName=tempo packageName=grafana/tempo
ARG TEMPO_VERSION=v2.7.2
# renovate: datasource=github-releases depName=loki packageName=grafana/loki
ARG LOKI_VERSION=v3.4.3
# renovate: datasource=github-releases depName=pyroscope packageName=grafana/pyroscope
ARG PYROSCOPE_VERSION=v1.13.1
# renovate: datasource=github-releases depName=opentelemetry-collector packageName=open-telemetry/opentelemetry-collector-releases
ARG OPENTELEMETRY_COLLECTOR_VERSION=v0.123.1

# hadolint global ignore=DL3059
FROM redhat/ubi9:9.5-1744101466 AS builder

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
 otelcol-config*.yaml \
 run-otelcol.sh \
 run-all.sh \
 /otel-lgtm/

# hadolint ignore=DL3033
RUN yum install -y unzip dos2unix jq procps

# hadolint ignore=SC2038,DL4006
RUN find /otel-lgtm/ -maxdepth 1 -type f | xargs dos2unix

COPY download-grafana.sh \
 download-prometheus.sh \
 download-tempo.sh \
 download-loki.sh \
 download-pyroscope.sh \
 download-otelcol.sh \
 install-cosign.sh \
 ./

# TARGETARCH is automatically detected and set by the Docker daemon during the build process. If the build starts
# on an amd64 architecture, than the TARGETARCH will be set to `amd64`.
# More details on the variables can be found here: https://docs.docker.com/desktop/extensions-sdk/extensions/multi-arch/
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# renovate: datasource=github-releases depName=cosign packageName=sigstore/cosign
ARG COSIGN_VERSION=v2.5.0

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

COPY grafana-datasources.yaml /otel-lgtm/grafana/conf/provisioning/datasources/
COPY grafana-dashboards.yaml /otel-lgtm/grafana/conf/provisioning/dashboards/

FROM redhat/ubi9-micro:9.5-1744118077

RUN mkdir /otel-lgtm
WORKDIR /otel-lgtm

COPY --from=builder --chown=0:0 /usr/bin/curl /usr/bin/jq /usr/bin/grep /usr/bin/
# jq
COPY --from=builder --chown=0:0 /usr/lib64/libjq.so.1 \
 /usr/lib64/libonig.so.5 \
 # curl
 /usr/lib64/libkeyutils.so* \
 /usr/lib64/libz.so* \
 /usr/lib64/libkrb5support.so* \
 /usr/lib64/libkrb5.so* \
 /usr/lib64/libk5crypto.so* \
 /usr/lib64/libgssapi_krb5.so* \
 /usr/lib64/libcom_err.so* \
 /usr/lib64/libssl.so* \
 /usr/lib64/libcrypto.so* \
 /usr/lib64/libcurl.so* \
 /usr/lib64/libnghttp2.so* \
 /usr/lib64/libresolv.so* \
 # grep
 /usr/lib64/libpcre.so.1 \
 /usr/lib64/libsigsegv.so.2 /lib64/libsigsegv.so.2 \
 /lib64/

COPY --from=builder /otel-lgtm /otel-lgtm

# just for displaying the version in the startup message
ARG GRAFANA_VERSION
ARG PROMETHEUS_VERSION
ARG TEMPO_VERSION
ARG LOKI_VERSION
ARG PYROSCOPE_VERSION
ARG OPENTELEMETRY_COLLECTOR_VERSION
ENV GRAFANA_VERSION=${GRAFANA_VERSION}
ENV PROMETHEUS_VERSION=${PROMETHEUS_VERSION}
ENV TEMPO_VERSION=${TEMPO_VERSION}
ENV LOKI_VERSION=${LOKI_VERSION}
ENV PYROSCOPE_VERSION=${PYROSCOPE_VERSION}
ENV OPENTELEMETRY_COLLECTOR_VERSION=${OPENTELEMETRY_COLLECTOR_VERSION}

CMD ["/otel-lgtm/run-all.sh"]
