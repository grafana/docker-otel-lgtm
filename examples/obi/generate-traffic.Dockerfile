FROM curlimages/curl:8.22.0@sha256:58adaa4e8dca9c988bae2aba4ab3434a0bb2da16bbe3f92dec39ec7785166777

COPY generate-traffic.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
