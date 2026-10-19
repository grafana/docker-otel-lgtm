FROM curlimages/curl:8.23.0@sha256:a134550be58ab783810e613ae96fd253c38f7bdd16d9bf9be350700c7a29ac06

COPY generate-traffic.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/generate-traffic.sh"]
