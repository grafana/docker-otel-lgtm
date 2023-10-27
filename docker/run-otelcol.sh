#!/bin/bash

./otelcol-contrib-$OPENTELEMETRY_COLLECTOR_VERSION/otelcol-contrib --config=file:./otelcol-config.yaml --feature-gates=pkg.translator.prometheus.NormalizeName > /dev/null 2>&1
