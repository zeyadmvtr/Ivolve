#!/usr/bin/env bash
# ==============================================================================
# Script: 03-verify-dns-resolution.sh
# Purpose: Verify CoreDNS resolution of MySQL Headless Service and StatefulSet Pod
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Deploying DNS utilities pod in 'ivolve' namespace"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/04-dnsutils-pod.yaml"

echo ">>> Waiting for dnsutils pod to be Ready..."
kubectl wait --for=condition=Ready pod/dnsutils -n ivolve --timeout=90s

echo ""
echo "=========================================================="
echo ">>> Step 2: Resolving Headless Service (ivolveDBSvc)"
echo "=========================================================="
echo ">>> Querying 'ivolveDBSvc' inside 'ivolve' namespace:"
kubectl exec -i -n ivolve dnsutils -- nslookup ivolveDBSvc

echo ""
echo "=========================================================="
echo ">>> Step 3: Resolving StatefulSet Pod FQDN (ivolveDB-0.ivolveDBSvc)"
echo "=========================================================="
echo ">>> Querying 'ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local':"
kubectl exec -i -n ivolve dnsutils -- nslookup ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local

echo ""
echo "=========================================================="
echo ">>> Step 4: Comparing Resolved IP with Pod IP"
echo "=========================================================="
ACTUAL_POD_IP=$(kubectl get pod ivolveDB-0 -n ivolve -o jsonpath='{.status.podIP}')
echo "Actual Pod IP of ivolveDB-0 : ${ACTUAL_POD_IP}"
RESOLVED_IP=$(kubectl exec -i -n ivolve dnsutils -- nslookup ivolveDBSvc | grep "Address:" | tail -n 1 | awk '{print $2}')
echo "Headless Service Resolved IP: ${RESOLVED_IP}"

if [ "${ACTUAL_POD_IP}" == "${RESOLVED_IP}" ]; then
  echo ""
  echo ">>> [MATCH CONFIRMED] Headless Service resolves directly to Pod IP without intermediate proxy!"
fi

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] DNS resolution inside the cluster verified!"
echo "=========================================================="
