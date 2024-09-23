#!/bin/bash

set -euo pipefail

docker build -f Dockerfile -t "dice:1.1-SNAPSHOT" ..
