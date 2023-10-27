#!/bin/bash

./loki-$LOKI_VERSION/loki-linux-amd64  --config.file=./loki-config.yaml > /dev/null 2>&1
