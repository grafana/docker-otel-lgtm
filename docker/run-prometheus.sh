#!/bin/bash

./prometheus/prometheus \
      --web.enable-remote-write-receiver \
      --enable-feature=otlp-write-receiver \
      --enable-feature=exemplar-storage \
      --enable-feature=native-histograms \
      --storage.tsdb.path=/data/prometheus \
      --config.file=./prometheus.yaml > /dev/null 2>&1
