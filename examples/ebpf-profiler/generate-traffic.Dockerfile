FROM ubuntu:26.04@sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update && apt-get -y install curl

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
