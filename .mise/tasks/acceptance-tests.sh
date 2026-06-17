#!/usr/bin/env bash
#MISE description="Run OATs acceptance tests against LGTM builds"
#USAGE arg "<version>" help="The version tag for docker" default=""

set -euo pipefail

version=${usage_version:-$(date +%Y%m%d%H%M%S)}

echo "using version $version"

# Force Docker: oats hardcodes `docker compose`, so the image must be built with Docker.
./build-lgtm.sh "$version" docker

# renovate: datasource=github-releases depName=gcx packageName=grafana/gcx
export GCX_VERSION=v0.4.0
go install "github.com/grafana/gcx/cmd/gcx@${GCX_VERSION}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
git clone --depth 1 --branch v2 https://github.com/grafana/oats "$workdir/oats-src"
GOWORK=off go -C "$workdir/oats-src" build -o "$workdir/oats" ./cmd/v2

export LGTM_IMAGE="grafana/otel-lgtm:${version}"
REAL_GCX_BIN="$(go env GOPATH)/bin/gcx" \
	"$workdir/oats" \
	--config oats.toml \
	--gcx ./ci/oats/gcx-wrapper.sh \
	--no-cache \
	--timeout=3m \
	-v 2
