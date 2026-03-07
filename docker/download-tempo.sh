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

ARCHIVE=tempo_"${VERSION:1}"_linux_"${TARGETARCH}".tar.gz
curl -sOL https://github.com/grafana/tempo/releases/download/"${VERSION}"/SHA256SUMS
curl -sOL https://github.com/grafana/tempo/releases/download/"${VERSION}"/"${ARCHIVE}"
sha256sum -c SHA256SUMS --ignore-missing
mkdir /otel-lgtm/tempo
tar xfz "${ARCHIVE}" -C /otel-lgtm/tempo/
