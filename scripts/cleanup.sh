#!/usr/bin/env bash
# Removes the test app, the IP pool and MetalLB itself.
set -uo pipefail
cd "$(dirname "$0")/.."

METALLB_VERSION="${METALLB_VERSION:-v0.15.2}"

kubectl delete svc,deployment nginx-test --ignore-not-found
kubectl delete -f manifests/l2advertisement.yaml -f manifests/ipaddresspool.yaml --ignore-not-found
kubectl delete -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml" --ignore-not-found
