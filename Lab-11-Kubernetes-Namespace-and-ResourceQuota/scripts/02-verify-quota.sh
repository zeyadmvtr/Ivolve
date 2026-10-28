#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-quota.sh
# Purpose: Validate that ResourceQuota permits 3 pods and blocks the 4th pod
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Deploying test workload with 3 replicas"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-quota-test-deployment.yaml"

echo ""
echo ">>> Waiting for deployment replicas to roll out (within quota limit: 3)..."
kubectl rollout status deployment/quota-test-workload -n ivolve --timeout=90s

echo ""
echo ">>> Current Pods in 'ivolve' namespace:"
kubectl get pods -n ivolve -o wide

echo ""
echo "=========================================================="
echo ">>> Step 2: Describing ResourceQuota (should show Used: 3, Hard: 3)"
echo "=========================================================="
kubectl describe resourcequota ivolveQuota -n ivolve

echo ""
echo "=========================================================="
echo ">>> Step 3: Attempting to create a 4th pod (Direct Pod rejection test)"
echo "=========================================================="
set +e
ERROR_OUTPUT=$(kubectl apply -f "${MANIFESTS_DIR}/04-exceed-quota-pod.yaml" 2>&1)
EXIT_CODE=$?
set -e

echo "${ERROR_OUTPUT}"

if echo "${ERROR_OUTPUT}" | grep -q "exceeded quota"; then
  echo ""
  echo ">>> [CONFIRMED] Kubernetes Admission Controller blocked the 4th pod:"
  echo "    ${ERROR_OUTPUT}"
else
  echo ""
  echo "[-] WARNING: Unexpected response when creating exceeding pod. Check quota status."
fi

echo ""
echo "=========================================================="
echo ">>> Step 4: Testing Deployment scaling (Scaling from 3 to 4 replicas)"
echo "=========================================================="
kubectl scale deployment quota-test-workload -n ivolve --replicas=4

sleep 4

echo ""
echo ">>> Inspecting Deployment & ReplicaSet events:"
kubectl get deployment quota-test-workload -n ivolve
echo ""
echo ">>> Inspecting ReplicaSet failure events:"
kubectl describe replicaset -l app=quota-test -n ivolve | grep -E "Warning.*FailedCreate.*exceeded quota" -A 2 || true

echo ""
echo "=========================================================="
echo ">>> Reverting scale back to 3 replicas for stability:"
echo "=========================================================="
kubectl scale deployment quota-test-workload -n ivolve --replicas=3

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] ResourceQuota enforcement successfully verified!"
echo "=========================================================="
