#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

# Set TARGETARCH if not set (fallback for non-buildx builds)
if [[ -z "${TARGETARCH}" ]]; then
	ARCH=$(uname -m)
	case "${ARCH}" in
		x86_64)
			TARGETARCH="amd64"
			;;
		aarch64|arm64)
			TARGETARCH="arm64"
			;;
		*)
			echo "Unsupported architecture: ${ARCH}"
			exit 1
			;;
	esac
	echo "TARGETARCH not set, detected: ${TARGETARCH}"
fi

API_URL="https://grafana.com/api/downloads/grafana/versions/${VERSION:1}/packages/${TARGETARCH}/linux"
echo "Fetching metadata from: ${API_URL}"
API_RESPONSE=$(curl -sL "${API_URL}" -H 'accept: application/json')
DOWNLOAD_URL=$(echo "${API_RESPONSE}" | jq -r '.url')
CHECKSUM=$(echo "${API_RESPONSE}" | jq -r '.sha256')
ARCHIVE=$(basename "${DOWNLOAD_URL}")

echo "Downloading: ${DOWNLOAD_URL}"
curl -sOL "${DOWNLOAD_URL}"
echo "Verifying checksum..."
echo "${CHECKSUM} ${ARCHIVE}" | sha256sum -c
echo "Extracting archive..."
EXTRACTED_DIR=$(tar -tzf "${ARCHIVE}" | head -1 | cut -f1 -d"/" || true)
tar xfz "${ARCHIVE}"
echo "Moving ${EXTRACTED_DIR} to /otel-lgtm/grafana/"
mv "${EXTRACTED_DIR}" /otel-lgtm/grafana/
