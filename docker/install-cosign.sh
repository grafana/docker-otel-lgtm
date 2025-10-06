#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi
VERSION="${VERSION:1}"

ARCH=$(uname -m)
if [[ "${ARCH}" == "x86_64" ]]; then
	ARCH="x86_64"
elif [[ "${ARCH}" == "aarch64" ]]; then
	ARCH="aarch64"
elif [[ "${ARCH}" == "arm64" ]]; then
	ARCH="aarch64"
else
	echo "Unsupported architecture: ${ARCH}"
	exit 1
fi
ARCHIVE=cosign-"${VERSION}"-1."${ARCH}".rpm

cd /tmp
curl -O -L https://github.com/sigstore/cosign/releases/download/"${VERSION}"/"${ARCHIVE}"
curl -O -L https://github.com/sigstore/cosign/releases/download/"${VERSION}"/cosign_checksums.txt
sha256sum -c cosign_checksums.txt --ignore-missing
yum install -y "${ARCHIVE}"
