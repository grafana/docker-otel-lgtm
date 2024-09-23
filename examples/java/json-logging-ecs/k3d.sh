#!/bin/bash

set -euo pipefail

./build.sh
k3d cluster create jsonlogging || k3d cluster start jsonlogging
k3d image import -c jsonlogging dice:1.1-SNAPSHOT

kubectl apply -f k8s/

kubectl wait --for=condition=ready pod -l app=dice
kubectl wait --for=condition=ready --timeout=5m pod -l app=lgtm

kubectl port-forward service/dice 8080:8080 &
kubectl port-forward service/lgtm 3000:3000 &
