#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
	TESTDIR=$(mktemp -d)
	export GF_PATHS_HOME="$TESTDIR/grafana"
	export GF_PATHS_PLUGINS="$GF_PATHS_HOME/plugins"
	MARKER="$GF_PATHS_HOME/.otel-lgtm-grafana-version"

	# shellcheck source=/dev/null
	source "$BATS_TEST_DIRNAME/grafana-plugins.sh"
}

teardown() {
	rm -rf "$TESTDIR"
}

# Create the four managed plugin directories with a marker file inside each so
# we can assert whether they were removed.
seed_managed_plugins() {
	local plugin
	for plugin in "${GRAFANA_MANAGED_PLUGINS[@]}"; do
		mkdir -p "$GF_PATHS_PLUGINS/$plugin"
		touch "$GF_PATHS_PLUGINS/$plugin/module.js"
	done
}

@test "fresh install writes the version marker and cleans nothing" {
	GRAFANA_VERSION=v13.1.0 run refresh_stale_managed_plugins
	[ "$status" -eq 0 ]
	[ -f "$MARKER" ]
	[ "$(cat "$MARKER")" = "v13.1.0" ]
}

@test "same version is a no-op and keeps existing plugins" {
	seed_managed_plugins
	printf '%s\n' "v13.1.0" >"$MARKER"

	GRAFANA_VERSION=v13.1.0 run refresh_stale_managed_plugins
	[ "$status" -eq 0 ]
	[ -d "$GF_PATHS_PLUGINS/grafana-metricsdrilldown-app" ]
	[ -d "$GF_PATHS_PLUGINS/grafana-pyroscope-app" ]
}

@test "changed version removes all managed plugins and updates the marker" {
	seed_managed_plugins
	printf '%s\n' "v13.0.1" >"$MARKER"

	GRAFANA_VERSION=v13.1.0 run refresh_stale_managed_plugins
	[ "$status" -eq 0 ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-metricsdrilldown-app" ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-lokiexplore-app" ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-exploretraces-app" ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-pyroscope-app" ]
	[ "$(cat "$MARKER")" = "v13.1.0" ]
}

@test "existing volume without a marker is treated as stale and refreshed" {
	seed_managed_plugins

	GRAFANA_VERSION=v13.1.0 run refresh_stale_managed_plugins
	[ "$status" -eq 0 ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-metricsdrilldown-app" ]
	[ "$(cat "$MARKER")" = "v13.1.0" ]
}

@test "unmanaged plugins are preserved when refreshing" {
	seed_managed_plugins
	mkdir -p "$GF_PATHS_PLUGINS/grafana-clock-panel"
	touch "$GF_PATHS_PLUGINS/grafana-clock-panel/module.js"
	printf '%s\n' "v13.0.1" >"$MARKER"

	GRAFANA_VERSION=v13.1.0 run refresh_stale_managed_plugins
	[ "$status" -eq 0 ]
	[ -d "$GF_PATHS_PLUGINS/grafana-clock-panel" ]
	[ ! -e "$GF_PATHS_PLUGINS/grafana-metricsdrilldown-app" ]
}
