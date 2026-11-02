FROM curlimages/curl:8.23.0@sha256:3fb7e13e5d179a845c97d78204f3f1064d1907037f26a3ebf91710571151fd93

COPY generate-traffic.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
