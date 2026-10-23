FROM curlimages/curl:8.23.0@sha256:11e64e28c5f58c8d93ee95fcf22ac055f48b0bc440e0ce7d8013bbb5ad6aa8ac

COPY generate-traffic.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
