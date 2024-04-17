#!/bin/bash

./otelcol-contrib/otelcol-contrib \
	--config=file:./otelcol-config.yaml \
	> /dev/null 2>&1
