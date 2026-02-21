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

ARCHIVE=pyroscope_"${VERSION:1}"_linux_"${TARGETARCH}".tar.gz
curl -sOL https://github.com/grafana/pyroscope/releases/download/"${VERSION}"/checksums.txt
curl -sOL https://github.com/grafana/pyroscope/releases/download/"${VERSION}"/"${ARCHIVE}"
sha256sum -c checksums.txt --ignore-missing
mkdir /otel-lgtm/pyroscope
tar xfz "${ARCHIVE}" -C /otel-lgtm/pyroscope/
