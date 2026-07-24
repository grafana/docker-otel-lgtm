FROM curlimages/curl:8.18.0@sha256:d94d07ba9e7d6de898b6d96c1a072f6f8266c687af78a74f380087a0addf5d17

COPY generate-traffic.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
