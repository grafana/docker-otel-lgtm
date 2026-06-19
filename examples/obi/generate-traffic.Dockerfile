FROM ubuntu:26.04@sha256:e153663f92c94118ff22a5dc397b59b351ffd695480566debb5850e017e5937a

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
