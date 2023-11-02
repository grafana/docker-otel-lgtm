#!/bin/bash

./otelcol-contrib-$OPENTELEMETRY_COLLECTOR_VERSION/otelcol-contrib \
	--config=file:./otelcol-config.yaml \
	> /dev/null 2>&1
