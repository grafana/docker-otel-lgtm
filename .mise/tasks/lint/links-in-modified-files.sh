#!/usr/bin/env bash
#MISE description="Lint links in modified files"
#MISE hide=true

set -euo pipefail

#USAGE flag "--base <base>" help="base branch to compare against (default: origin/main)" default="origin/main"
#USAGE flag "--head <head>" help="head branch to compare against (empty for local changes) (default: empty)" default=""
#USAGE flag "--lychee-args <args>" help="extra arguments to pass to lychee"

if [ "$usage_head" = "''" ]; then
	usage_head=""
fi

lychee_args_flag=()
if [ -n "${usage_lychee_args:-}" ]; then
	lychee_args_flag=(--lychee-args "$usage_lychee_args")
fi

# Check if lychee config was modified
# - because usage_head may be empty
# shellcheck disable=SC2154,SC2086 # usage_* vars are set by mise; usage_head may be empty
config_modified=$(git diff --name-only --merge-base "$usage_base" $usage_head |
	grep -E '^(\.github/config/lychee\.toml|\.mise/tasks/lint/.*|mise\.toml)$' || true)

if [ -n "$config_modified" ]; then
	echo "config changes, checking all files."
	mise run lint:links "${lychee_args_flag[@]+"${lychee_args_flag[@]}"}"
else
	# Using lychee's default extension filter here to match when it runs against all files
	# Note: --diff-filter=d filters out deleted files
	# - because usage_head may be empty
	# shellcheck disable=SC2086 # intentional: usage_head may be empty
	modified_files=$(git diff --name-only --diff-filter=d "$usage_base" $usage_head |
		grep -E '\.(md|mkd|mdx|mdown|mdwn|mkdn|mkdown|markdown|html|htm|txt)$' |
		tr '\n' ' ' || true)

	if [ -z "$modified_files" ]; then
		echo "No modified files, skipping link linting."
		exit 0
	fi

	# shellcheck disable=SC2086 # intentional word splitting for file list
	mise run lint:links "${lychee_args_flag[@]+"${lychee_args_flag[@]}"}" $modified_files
fi
