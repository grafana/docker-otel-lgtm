FROM ubuntu:26.04@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

COPY generate-traffic.sh /usr/local/bin/

RUN apt-get update && apt-get -y install curl

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
