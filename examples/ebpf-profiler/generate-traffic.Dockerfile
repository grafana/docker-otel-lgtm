FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update && apt-get -y install curl

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
