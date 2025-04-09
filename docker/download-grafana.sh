#!/bin/bash

set -euo pipefail

# too complicated to have as inline script in dockerfile

ARCHIVE=grafana-"${GRAFANA_VERSION:1}".linux-"${TARGETARCH}".tar.gz
curl -sOL https://dl.grafana.com/oss/release/"${ARCHIVE}"
CHECKSUM_URL=https://grafana.com/api/downloads/grafana/versions/"${GRAFANA_VERSION:1}"/packages/"${TARGETARCH}"/linux
echo "$(curl -sL "${CHECKSUM_URL}" -H 'accept: application/json' | jq -r '.sha256') ${ARCHIVE}" | sha256sum -c
tar xfz "${ARCHIVE}"
rm "${ARCHIVE}"
mv grafana-"${GRAFANA_VERSION}" grafana/
