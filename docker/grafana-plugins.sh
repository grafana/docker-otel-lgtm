#!/usr/bin/env bash

# The Drilldown apps (Metrics, Logs, Traces, Profiles) are not bundled in the
# Grafana release archive this image downloads. Grafana pulls them from
# grafana.com at startup into GF_PATHS_PLUGINS, which lives under /data and can
# be persisted across container upgrades via a mounted volume.

# To make upgrades self-healing, remove these managed plugins whenever the
# Grafana version changes so they are re-downloaded fresh for the running
# version. The last-installed version is recorded in a marker file under
# GF_PATHS_HOME.

# Grafana-managed plugins that this image relies on Grafana to (re)install on
# startup. Grafana downloads these automatically (as needed) into GF_PATHS_PLUGINS,
# so removing them is safe and only forces a fresh, version-compatible download.
GRAFANA_MANAGED_PLUGINS=(
	grafana-exploretraces-app
	grafana-lokiexplore-app
	grafana-metricsdrilldown-app
	grafana-pyroscope-app
)

# Remove the managed plugins if the Grafana version has changed since they were
# last installed so Grafana re-downloads builds compatible with the running version.
refresh_stale_managed_plugins() {
	local plugins_dir="${GF_PATHS_PLUGINS:?GF_PATHS_PLUGINS must be set}"
	local home_dir="${GF_PATHS_HOME:?GF_PATHS_HOME must be set}"
	local version="${GRAFANA_VERSION:?GRAFANA_VERSION must be set}"
	local marker="${home_dir}/.otel-lgtm-grafana-version"

	# On a first run with no persisted plugins there is nothing stale to clean;
	# just record the running version for next time.
	if [ ! -d "${plugins_dir}" ]; then
		mkdir -p "${home_dir}"
		printf '%s\n' "${version}" >"${marker}"
		return 0
	fi

	local previous_version=""
	if [ -f "${marker}" ]; then
		previous_version=$(<"${marker}")
	fi

	# Plugins were already installed for the running Grafana version.
	if [ "${previous_version}" = "${version}" ]; then
		return 0
	fi

	if [ -n "${previous_version}" ]; then
		echo "Grafana version changed (${previous_version} -> ${version}); refreshing managed plugins so compatible builds are re-downloaded"
	else
		echo "No Grafana plugin version marker found; refreshing managed plugins to ensure builds match Grafana ${version}"
	fi

	local plugin
	for plugin in "${GRAFANA_MANAGED_PLUGINS[@]}"; do
		if [ -e "${plugins_dir}/${plugin}" ]; then
			echo "  Removing stale plugin: ${plugin}"
			rm -rf "${plugins_dir:?}/${plugin}"
		fi
	done

	mkdir -p "${home_dir}"
	printf '%s\n' "${version}" >"${marker}"
}
