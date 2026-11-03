#!/usr/bin/env bash

if (($# == 0)); then
	exec /otel-lgtm/run-all.sh
fi

case "$1" in
--otelcol-*) exec /otel-lgtm/run-all.sh "$@" ;;
*) exec "$@" ;;
esac
