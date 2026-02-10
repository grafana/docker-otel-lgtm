#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

ARCHIVE=beyla-linux-"${TARGETARCH}"-"${VERSION}".tar.gz

# Get expected digest from GitHub release API
EXPECTED_DIGEST=$(curl -fsSL "https://api.github.com/repos/grafana/beyla/releases/tags/${VERSION}" |
	jq -r ".assets[] | select(.name == \"${ARCHIVE}\") | .digest")

curl -fsSLo "${ARCHIVE}" "https://github.com/grafana/beyla/releases/download/${VERSION}/${ARCHIVE}"

# Verify checksum using digest from GitHub API
ACTUAL_DIGEST="sha256:$(sha256sum "${ARCHIVE}" | cut -d' ' -f1)"
if [[ "${ACTUAL_DIGEST}" != "${EXPECTED_DIGEST}" ]]; then
	echo "Checksum verification failed for ${ARCHIVE}"
	echo "Expected: ${EXPECTED_DIGEST}"
	echo "Actual:   ${ACTUAL_DIGEST}"
	exit 1
fi

mkdir /otel-lgtm/beyla
tar xfz "${ARCHIVE}" -C /otel-lgtm/beyla/
