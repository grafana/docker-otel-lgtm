FROM ubuntu:26.04@sha256:678c6550cc43645e08669028bc177f50be4e7c5b8cca677067b1914d4afc7a03

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update && apt-get -y install curl

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
