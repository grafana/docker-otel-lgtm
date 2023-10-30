#!/bin/bash

cd ./grafana-$GRAFANA_VERSION
./bin/grafana server > /dev/null 2>&1
