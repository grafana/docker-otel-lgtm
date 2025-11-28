#!/usr/bin/env bash
#MISE description="Run Super-Linter on the repository"

set -euo pipefail

pushd "$(dirname "$0")/.."

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

$RUNTIME image pull ghcr.io/super-linter/super-linter:latest

$RUNTIME container run --rm \
	-e RUN_LOCAL=true \
	-e DEFAULT_BRANCH=main \
	--env-file ".github/super-linter.env" \
	-v "$(pwd)":/tmp/lint:"${MOUNT_OPTS}" \
	ghcr.io/super-linter/super-linter:latest

popd
