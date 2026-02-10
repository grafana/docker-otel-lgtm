#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

ARCHIVE=beyla-linux-"${TARGETARCH}"-"${VERSION}".tar.gz
curl -sOL https://github.com/grafana/beyla/releases/download/"${VERSION}"/"${ARCHIVE}"
# Beyla releases don't publish checksums.txt — validate the archive is a valid tarball
tar tzf "${ARCHIVE}" >/dev/null
mkdir /otel-lgtm/beyla
tar xfz "${ARCHIVE}" -C /otel-lgtm/beyla/
