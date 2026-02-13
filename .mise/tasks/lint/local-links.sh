#!/usr/bin/env bash
#MISE description="Lint links in local files"

set -euo pipefail

#USAGE flag "--lychee-args <args>" help="extra arguments to pass to lychee"
#USAGE arg "<file>" var=#true help="files to check" default="."

eval "lychee_args=(${usage_lychee_args:-})"
# shellcheck disable=SC2154,SC2086 # usage_*/lychee_args are set by mise; intentional word splitting
lychee --scheme file --include-fragments --config .github/config/lychee.toml "${lychee_args[@]+"${lychee_args[@]}"}" -- $usage_file
