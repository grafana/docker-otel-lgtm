#!/usr/bin/env bash
#MISE description="Lint links in modified files"
#MISE hide=true

set -euo pipefail

#USAGE flag "--base <base>" help="base branch to compare against"
#USAGE flag "--head <head>" help="head commit to compare against"
#USAGE flag "--lychee-args <args>" help="extra arguments to pass to lychee"

# shellcheck disable=SC2154 # usage_* vars are set by mise
base="${usage_base:-origin/${GITHUB_BASE_REF:-main}}"
head="${usage_head:-${GITHUB_HEAD_SHA:-HEAD}}"

lychee_args_flag=()
if [ -n "${usage_lychee_args:-}" ]; then
	lychee_args_flag=(--lychee-args "$usage_lychee_args")
fi

# Check if lychee config was modified
# shellcheck disable=SC2086 # intentional: head may expand to empty
config_modified=$(git diff --name-only --merge-base "$base" $head |
	grep -E '^(\.github/config/lychee\.toml|\.mise/tasks/lint/.*|mise\.toml)$' || true)

if [ -n "$config_modified" ]; then
	echo "config changes, checking all files."
	mise run lint:links "${lychee_args_flag[@]+"${lychee_args_flag[@]}"}"
else
	# Using lychee's default extension filter here to match when it runs against all files
	# Note: --diff-filter=d filters out deleted files
	# shellcheck disable=SC2086 # intentional: head may expand to empty
	modified_files=$(git diff --name-only --merge-base --diff-filter=d "$base" $head |
		grep -E '\.(md|mkd|mdx|mdown|mdwn|mkdn|mkdown|markdown|html|htm|txt)$' |
		tr '\n' ' ' || true)

	if [ -z "$modified_files" ]; then
		echo "No modified files, skipping link linting."
		exit 0
	fi

	# shellcheck disable=SC2086 # intentional word splitting for file list
	mise run lint:links "${lychee_args_flag[@]+"${lychee_args_flag[@]}"}" $modified_files
fi
