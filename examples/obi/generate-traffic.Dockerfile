FROM ubuntu:24.04

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
