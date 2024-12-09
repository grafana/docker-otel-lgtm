#!/bin/bash

set -euo pipefail

k3d cluster create et || k3d cluster start et

kubectl apply -f k8s/

kubectl wait --for=condition=ready --timeout=5m pod -l app=lgtm

kubectl port-forward service/lgtm 3000:3000 &
kubectl port-forward service/lgtm 4318:4318 &
