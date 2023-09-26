#!/bin/bash

./otelcol-contrib-0.85.0/otelcol-contrib --config=file:./otelcol-config.yaml --feature-gates=pkg.translator.prometheus.NormalizeName > /dev/null 2>&1
