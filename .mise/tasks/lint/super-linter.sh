#!/usr/bin/env bash
#MISE description="Run Super-Linter with auto-fix on the repository"

set -xeuo pipefail

# check for SUPER_LINTER_VERSION env var, otherwise exit with error
if [ -z "${SUPER_LINTER_VERSION:-}" ]; then
	echo "SUPER_LINTER_VERSION environment variable is not set. Exiting."
	exit 1
fi

pushd "$(dirname "$0")/../../.."

if command -v podman >/dev/null 2>&1; then
	RUNTIME=podman
	# Fedora, by default, runs with SELinux on. We require the "z" option for bind mounts.
	# See: https://docs.docker.com/engine/storage/bind-mounts/#configure-the-selinux-label
	# See: https://docs.podman.io/en/stable/markdown/podman-run.1.html section "Labeling Volume Mounts"
	MOUNT_OPTS="rw,z"
elif command -v docker >/dev/null 2>&1; then
	RUNTIME=docker
	MOUNT_OPTS=rw
else
	echo "Unable to find a suitable container runtime such as Podman or Docker. Exiting."
	exit 1
fi

$RUNTIME image pull --platform linux/amd64 "ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"

$RUNTIME container run --rm --platform linux/amd64 \
	-e RUN_LOCAL=true \
	-e DEFAULT_BRANCH=main \
	--env-file ".github/config/super-linter.env" \
	-v "$(pwd)":/tmp/lint:"${MOUNT_OPTS}" \
	"ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"
popd
