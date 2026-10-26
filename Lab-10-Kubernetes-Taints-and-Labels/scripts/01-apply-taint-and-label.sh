#!/usr/bin/env bash
# ==============================================================================
# Script: 01-apply-taint-and-label.sh
# Purpose: Apply taint and label to a Kubernetes worker node and verify settings.
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

# Auto-detect the first worker node if not explicitly specified as an argument
if [ "$#" -ge 1 ]; then
  WORKER_NODE="$1"
else
  # Find node without control-plane role
  WORKER_NODE=$(kubectl get nodes --no-headers -l '!node-role.kubernetes.io/control-plane' -o custom-columns=":metadata.name" | head -n 1)
  if [ -z "${WORKER_NODE}" ]; then
    # Fallback if roles aren't set
    WORKER_NODE=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.name!="k8s-master")].metadata.name}' | awk '{print $1}')
  fi
fi

if [ -z "${WORKER_NODE}" ]; then
  echo "[-] ERROR: Could not automatically detect a worker node. Please pass the node name as an argument:"
  echo "    bash $0 <worker-node-name>"
  exit 1
fi

echo "=========================================================="
echo ">>> Target Worker Node: ${WORKER_NODE}"
echo "=========================================================="

echo ""
echo ">>> Step 1: Applying Taint (workload=ivolveApp:NoSchedule)..."
kubectl taint nodes "${WORKER_NODE}" workload=ivolveApp:NoSchedule --overwrite

echo ""
echo ">>> Step 2: Applying Label (project=ivolve)..."
kubectl label nodes "${WORKER_NODE}" project=ivolve --overwrite

echo ""
echo "=========================================================="
echo ">>> Step 3: Verifying Taint and Label via kubectl describe node"
echo "=========================================================="
kubectl describe node "${WORKER_NODE}" | grep -E "Name:|Roles:|Labels:|Taints:" -A 6

echo ""
echo "=========================================================="
echo ">>> Step 4: Verifying Labels via kubectl get nodes --show-labels"
echo "=========================================================="
kubectl get nodes --show-labels

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Taint and label successfully applied and verified on ${WORKER_NODE}!"
echo "=========================================================="
