#!/bin/bash

set -euo pipefail

export OTEL_SERVICE_NAME="dice-server"
export OTEL_SERVICE_VERSION="0.1.0"

npm install

npm start
