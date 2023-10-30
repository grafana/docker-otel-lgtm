#!/bin/bash

./prometheus-$PROMETHEUS_VERSION/prometheus \
      --web.enable-remote-write-receiver \
      --enable-feature=exemplar-storage \
      --enable-feature=native-histograms \
      --config.file=./prometheus.yaml > /dev/null 2>&1
