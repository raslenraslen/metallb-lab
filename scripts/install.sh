#!/usr/bin/env bash
# Installs a pinned MetalLB release, then applies the IP pool and the L2 advertisement.
set -euo pipefail
cd "$(dirname "$0")/.."

METALLB_VERSION="${METALLB_VERSION:-v0.15.2}"

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml"
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=180s
kubectl rollout status daemonset/speaker -n metallb-system --timeout=180s

# The pool goes through MetalLB's validating webhook, which can need a few
# more seconds after the controller is Available.
for attempt in $(seq 1 10); do
  if kubectl apply -f manifests/ipaddresspool.yaml -f manifests/l2advertisement.yaml; then
    exit 0
  fi
  sleep 3
done
echo "Could not apply the IP pool: check 'kubectl get pods -n metallb-system'" >&2
exit 1
