#!/usr/bin/env bash
# Detect TARGETARCH when not set by buildx (e.g. plain `docker build`)

if [[ -z "${TARGETARCH:-}" ]]; then
	case "$(uname -m)" in
	x86_64) TARGETARCH="amd64" ;;
	aarch64 | arm64) TARGETARCH="arm64" ;;
	*)
		echo "Unsupported architecture: $(uname -m)"
		exit 1
		;;
	esac
	export TARGETARCH
fi
