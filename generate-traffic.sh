#!/bin/bash

watch 'curl -s http://127.0.0.1:8080/rolldice; \
  curl -s http://127.0.0.1:8081/rolldice; \
  curl -s http://127.0.0.1:8082/rolldice; \
  curl -s http://127.0.0.1:8083/rolldice; \
  curl -s http://127.0.0.1:8084/rolldice?rolls=5'
