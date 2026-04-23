#!/bin/bash

set -euo pipefail

VERSION=${1:-}
if [[ -z "${VERSION}" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

# shellcheck disable=SC1091 # Flint 0.20.3 runs ShellCheck without source following.
source ./common.sh
source_sibling detect-arch.sh

ARCHIVE=otelcol-contrib_"${VERSION:1}"_linux_"${TARGETARCH}".tar.gz
URL=https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/"${VERSION}"/"${ARCHIVE}"
curl -sOL "${URL}".sig
curl -sOL "${URL}".pem
curl -sOL "${URL}"
cosign verify-blob \
	--certificate-identity-regexp github.com/open-telemetry/opentelemetry-collector-releases \
	--certificate-oidc-issuer https://token.actions.githubusercontent.com \
	--certificate "${ARCHIVE}".pem \
	--signature "${ARCHIVE}".sig \
	"${ARCHIVE}"
mkdir /otel-lgtm/otelcol-contrib
tar xfz "${ARCHIVE}" -C /otel-lgtm/otelcol-contrib/
