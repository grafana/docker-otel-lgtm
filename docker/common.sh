#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source_sibling() {
	# shellcheck source=/dev/null
	source "${SCRIPT_DIR}/$1"
}
