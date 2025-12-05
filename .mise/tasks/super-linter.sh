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

# Extract super-linter version from GitHub Actions workflow
# Format: uses: super-linter/super-linter@<SHA> # <tag>
# We use the version tag (e.g., v8.2.1) from the comment
SUPER_LINTER_VERSION=$(grep -E "super-linter/super-linter@" .github/workflows/super-linter.yml | sed -E 's/.*# (v[0-9]+\.[0-9]+\.[0-9]+).*/\1/' | head -1)

if [ -z "$SUPER_LINTER_VERSION" ]; then
	echo "Error: Could not extract super-linter version from .github/workflows/super-linter.yml"
	exit 1
fi

$RUNTIME image pull "ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"

$RUNTIME container run --rm \
	-e RUN_LOCAL=true \
	-e DEFAULT_BRANCH=main \
	--env-file ".github/super-linter.env" \
	-v "$(pwd)":/tmp/lint:"${MOUNT_OPTS}" \
	"ghcr.io/super-linter/super-linter:${SUPER_LINTER_VERSION}"

popd
