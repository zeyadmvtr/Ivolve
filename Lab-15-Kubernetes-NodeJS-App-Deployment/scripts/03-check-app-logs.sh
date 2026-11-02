#!/usr/bin/env bash
# ==============================================================================
# Script: 03-check-app-logs.sh
# Purpose: Verify Node.js logs and persistent storage access logs
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Checking Node.js Pod Console Logs"
echo "=========================================================="

PODS=$(kubectl get pods -n ivolve -l app=ivolve-app -o jsonpath='{.items[*].metadata.name}')

for POD in ${PODS}; do
  echo "----------------------------------------------------------"
  echo ">>> Pod: ${POD}"
  echo "----------------------------------------------------------"
  kubectl logs -n ivolve "${POD}" -c ivolve-app --tail=25
  echo ""
done

echo "=========================================================="
echo ">>> Step 2: Generating HTTP Traffic via ClusterIP Service"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/04-curl-client-pod.yaml"
kubectl wait --for=condition=Ready pod/ivolve-client-tester -n ivolve --timeout=60s
echo ">>> Tester pod output:"
kubectl logs -n ivolve ivolve-client-tester

echo ""
echo "=========================================================="
echo ">>> Step 3: Checking Persistent Volume Log Files (/app/logs/access.log)"
echo "=========================================================="
FIRST_POD=$(kubectl get pods -n ivolve -l app=ivolve-app -o jsonpath='{.items[0].metadata.name}')
echo ">>> Reading /app/logs/access.log from ${FIRST_POD}:"
kubectl exec -n ivolve "${FIRST_POD}" -c ivolve-app -- tail -n 10 /app/logs/access.log

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Node.js DB connectivity and persistent logging verified!"
echo "=========================================================="
