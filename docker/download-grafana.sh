#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

ARCHIVE=grafana-"${VERSION:1}".linux-"${TARGETARCH}".tar.gz
curl -sOL https://dl.grafana.com/oss/release/"${ARCHIVE}"
CHECKSUM_URL=https://grafana.com/api/downloads/grafana/versions/"${VERSION:1}"/packages/"${TARGETARCH}"/linux
echo "$(curl -sL "${CHECKSUM_URL}" -H 'accept: application/json' | jq -r '.sha256') ${ARCHIVE}" | sha256sum -c
tar xfz "${ARCHIVE}"
mv grafana-"${VERSION}" /otel-lgtm/grafana/
