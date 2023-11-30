#!/bin/bash

cd ./grafana-v$GRAFANA_VERSION
./bin/grafana server > /dev/null 2>&1
