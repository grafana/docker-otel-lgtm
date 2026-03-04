#!/usr/bin/env sh

set -eu

check_service(){
	name=$1
	url=$2

	echo "Checking $name"

	set +e
	#check if port is listening
	curl -fsS "$url" >/dev/null 2>&1
	code=$?
	set -e

	if [ "$code" -eq 7 ]; then
		echo "$name not running (skipping)"
	elif [ "$code" -eq 0 ]; then
		echo "$name healthy"
	else
		echo "$name unhealthy"
		exit 1
	fi
}

check_service "Grafana" http://localhost:3000/api/health
check_service "Loki" http://localhost:3100/ready
check_service "Tempo" http://localhost:3200/ready
check_service "Mimir" http://localhost:9090/-/ready
check_service "OTel Collector" http://localhost:13133/ready
