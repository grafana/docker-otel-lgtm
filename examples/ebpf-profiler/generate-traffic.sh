#!/bin/sh

watch 'curl -s http://java:8080/rolldice; \
  curl -s http://go:8081/rolldice; \
  curl -s http://python:8082/rolldice; \
  curl -s http://dotnet:8083/rolldice; \
  curl -s http://nodejs:8084/rolldice?rolls=5'
