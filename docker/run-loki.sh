#!/bin/bash

./loki/loki-linux-${TARGETARCH}  --config.file=./loki-config.yaml > /dev/null 2>&1
