#!/bin/bash

while true; do
	curl -s http://java:8080/rolldice || echo "error reaching java service"
	curl -s http://go:8081/rolldice || echo "error reaching go service"
	curl -s http://python:8082/rolldice || echo "error reaching python service"
	curl -s http://dotnet:8083/rolldice || echo "error reaching dotnet service"
	curl -s http://nodejs:8084/rolldice || echo "error reaching nodejs service"
	sleep 1
done
