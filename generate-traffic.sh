#!/bin/bash

echo "Generating traffic to the shop service at $(date)"

# generate a request every 100ms
# run for 5s and kill
watch -n 0.1 'curl -s http://localhost:8081/shop' & sleep 600 ; kill $!
