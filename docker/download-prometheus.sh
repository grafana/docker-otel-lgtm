#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

ARCHIVE=prometheus-"${VERSION:1}".linux-"${TARGETARCH}"
curl -sOL https://github.com/prometheus/prometheus/releases/download/"${VERSION}"/sha256sums.txt
curl -sOL https://github.com/prometheus/prometheus/releases/download/"${VERSION}"/"${ARCHIVE}".tar.gz
sha256sum -c sha256sums.txt --ignore-missing
# Extract directly to target dir to avoid tar failures under QEMU emulation (arm64 cross-build)
mkdir -p /otel-lgtm/prometheus
tar xfz "${ARCHIVE}".tar.gz --strip-components=1 -C /otel-lgtm/prometheus/
