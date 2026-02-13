#!/usr/bin/env bash
#MISE description="Lint links in all files"

set -euo pipefail

#USAGE flag "--lychee-args <args>" help="extra arguments to pass to lychee"
#USAGE arg "<file>" var=#true help="files to check" default="."

eval "lychee_args=(${usage_lychee_args:-})"
lychee --config .github/config/lychee.toml "${lychee_args[@]+"${lychee_args[@]}"}" $usage_file
