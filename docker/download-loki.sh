#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

ARCHIVE=loki-linux-"${TARGETARCH}".zip
curl -sOL https://github.com/grafana/loki/releases/download/"${VERSION}"/SHA256SUMS
curl -sOL https://github.com/grafana/loki/releases/download/"${VERSION}"/"${ARCHIVE}"
sha256sum -c SHA256SUMS --ignore-missing
mkdir /otel-lgtm/loki
unzip "${ARCHIVE}" -d /loki/
mv loki/loki-linux-"${TARGETARCH}" /otel-lgtm/loki/loki
