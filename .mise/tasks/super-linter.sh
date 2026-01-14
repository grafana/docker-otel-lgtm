#!/usr/bin/env bash
#MISE description="Run Super-Linter with auto-fix on the repository"

set -xeuo pipefail

pushd "$(dirname "$0")/../.."

if command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
	MOUNT_OPTS=rw
elif command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
	# Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
	# See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
	# See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
	MOUNT_OPTS="rw,z"
else
	echo "Unable to find a suitable container runtime such as Docker or Podman. Exiting."
	exit 1
fi

# renovate: datasource=docker depName=ghcr.io/super-linter/super-linter
SUPER_LINTER_VERSION="v8.2.1@sha256:6331793e23be44827ade3bfcd27c2c3f0870c663fb2b118db38035f4e59ab136"

$RUNTIME image pull --platform linux/amd64 "ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"

$RUNTIME container run --rm --platform linux/amd64 \
	-e RUN_LOCAL=true \
	-e DEFAULT_BRANCH=main \
	--env-file ".github/super-linter.env" \
	-v "$(pwd)":/tmp/lint:"${MOUNT_OPTS}" \
	"ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"
popd
