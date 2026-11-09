#!/usr/bin/env bash
# Exposes an nginx Deployment as a LoadBalancer Service, waits for MetalLB to
# assign an IP from the pool, and checks that nginx answers on that IP.
set -euo pipefail

kubectl create deployment nginx-test --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout status deployment/nginx-test --timeout=120s
kubectl expose deployment nginx-test --type=LoadBalancer --port=80 --dry-run=client -o yaml | kubectl apply -f -

ip=""
for attempt in $(seq 1 30); do
  ip=$(kubectl get svc nginx-test -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [[ -n "$ip" ]] && break
  sleep 2
done
if [[ -z "$ip" ]]; then
  echo "FAIL  no external IP assigned (check the pool range and 'kubectl describe svc nginx-test')"
  exit 1
fi

if curl -fsS --max-time 5 "http://${ip}" | grep -q "Welcome to nginx"; then
  echo "PASS  nginx answers on http://${ip}"
else
  echo "FAIL  ${ip} was assigned but does not answer (is this machine on the same LAN?)"
  exit 1
fi
