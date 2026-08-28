#!/usr/bin/env bash
# Consumer parity wrapper for Flint's lychee orchestration (V12 PoC).
set -euo pipefail

config=.github/config/lychee.toml
files=("$@")
repo_root=$(pwd)
config="$repo_root/$config"

if [ "${CI:-}" = "true" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
	printf '%s\n' 'flint: links: missing required CI environment variable: GITHUB_TOKEN' >&2
	exit 1
fi

cache_args=()
if [ "${CI:-}" != "true" ] && [ "${FLINT_LYCHEE_SKIP_LOCAL_CACHE:-}" != "true" ]; then
	mkdir -p .lychee_cache
	printf '%s\n' '*' >.lychee_cache/.gitignore
	cache_args=(--cache)
fi

remaps=()
if [ "${LYCHEE_SKIP_GITHUB_REMAPS:-}" != "true" ]; then
	repo="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url 2>/dev/null | sed -n 's|.*github\.com[:/]\(.*\)\.git$|\1|p; s|.*github\.com[:/]\(.*\)$|\1|p' | head -1)}"
	base="${GITHUB_BASE_REF:-main}"
	head="${GITHUB_HEAD_REF:-$(git branch --show-current)}"
	if [ -n "$repo" ] && [ "$head" != "$base" ]; then
		base_url="https://github.com/$repo"
		# PR-specific blob and tree remaps come first: lychee is first-match-wins.
		remaps+=(--remap "^${base_url}/blob/${base}/(.*?)#L[0-9]+.*\$ file://${PWD}/\$1")
		remaps+=(--remap "^${base_url}/blob/${base}/(.*?)#:~:text=.*\$ file://${PWD}/\$1")
		remaps+=(--remap "^${base_url}/blob/${base}/(.*)\$ file://${PWD}/\$1")
		remaps+=(--remap "^${base_url}/tree/${base}/(.*?)#L[0-9]+.*\$ file://${PWD}/\$1")
		remaps+=(--remap "^${base_url}/tree/${base}/(.*)\$ file://${PWD}/\$1")
	fi
	# shellcheck disable=SC2016 # regex capture groups are for lychee, not Bash.
	remaps+=(--remap '^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.*?)#L[0-9]+.*$ https://raw.githubusercontent.com/$1/$2/$3')
	# shellcheck disable=SC2016 # regex capture groups are for lychee, not Bash.
	remaps+=(--remap '^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.*?)#:~:text=.*$ https://raw.githubusercontent.com/$1/$2/$3')
	# shellcheck disable=SC2016 # regex capture groups are for lychee, not Bash.
	remaps+=(--remap '^https://github.com/([^/]+/[^/]+)/blob/([^/]+)/(.*)$ https://raw.githubusercontent.com/$1/$2/$3')
	# shellcheck disable=SC2016 # regex capture groups are for lychee, not Bash.
	remaps+=(--remap '^https://github.com/([^/]+/[^/]+)/(issues|pull)/([0-9]+)#issuecomment-.*$ https://github.com/$1/$2/$3')
fi

if [ "${#files[@]}" -gt 0 ]; then
	if [ "${#cache_args[@]}" -gt 0 ]; then
		(
			cd .lychee_cache
			lychee --config "$config" "${cache_args[@]}" "${remaps[@]}" "${files[@]/#/$repo_root/}"
		)
	else
		lychee --config "$config" "${remaps[@]}" "${files[@]}"
	fi
fi

# Flint's check_all_local safeguard: verify every local link and fragment.
all_files=()
while IFS= read -r file; do all_files+=("$file"); done < <(git ls-files '*.md' '*.mkd' '*.mdx' '*.mdown' '*.mdwn' '*.mkdn' '*.mkdown' '*.markdown' '*.html' '*.htm' '*.txt')
if [ "${#all_files[@]}" -gt 0 ]; then
	lychee --config "$config" --scheme file --include-fragments "${all_files[@]}"
fi
