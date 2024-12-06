#!/bin/bash

# generate a request every 10ms
# run for 5s and kill
watch -n 0.01 'curl -s http://localhost:8081/shop' & sleep 60 ; kill $!
