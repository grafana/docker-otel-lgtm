#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

source ./detect-arch.sh

API_URL="https://grafana.com/api/downloads/grafana/versions/${VERSION:1}/packages/${TARGETARCH}/linux"
API_RESPONSE=$(curl -fsL "${API_URL}" -H 'accept: application/json')
DOWNLOAD_URL=$(echo "${API_RESPONSE}" | jq -r '.url')
CHECKSUM=$(echo "${API_RESPONSE}" | jq -r '.sha256')
ARCHIVE=$(basename "${DOWNLOAD_URL}")

curl -fsOL "${DOWNLOAD_URL}"
echo "${CHECKSUM} ${ARCHIVE}" | sha256sum -c
tar xfz "${ARCHIVE}"
EXTRACTED_DIR=$(tar -tzf "${ARCHIVE}" | head -1 | cut -f1 -d"/" || true)
mv "${EXTRACTED_DIR}" /otel-lgtm/grafana/
