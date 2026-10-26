#!/usr/bin/env bash
# ==============================================================================
# Script: 03-cleanup.sh
# Purpose: Delete test workloads and remove taints and labels from worker node.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifests"

# Auto-detect target worker node
if [ "$#" -ge 1 ]; then
  WORKER_NODE="$1"
else
  WORKER_NODE=$(kubectl get nodes --no-headers -l '!node-role.kubernetes.io/control-plane' -o custom-columns=":metadata.name" | head -n 1)
  if [ -z "${WORKER_NODE}" ]; then
    WORKER_NODE=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.name!="k8s-master")].metadata.name}' | awk '{print $1}')
  fi
fi

echo "=========================================================="
echo ">>> Step 1: Deleting Test Workloads"
echo "=========================================================="
kubectl delete -f "${MANIFEST_DIR}/01-untainted-default-pod.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFEST_DIR}/02-tolerated-pod.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFEST_DIR}/03-targeted-ivolveapp-deployment.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFEST_DIR}/04-node-affinity-ivolveapp.yaml" --ignore-not-found=true

if [ -n "${WORKER_NODE}" ]; then
  echo ""
  echo "=========================================================="
  echo ">>> Step 2: Removing Taint (workload=ivolveApp:NoSchedule-)"
  echo "=========================================================="
  kubectl taint nodes "${WORKER_NODE}" workload=ivolveApp:NoSchedule- 2>/dev/null || echo "Taint already removed."

  echo ""
  echo "=========================================================="
  echo ">>> Step 3: Removing Label (project-)"
  echo "=========================================================="
  kubectl label nodes "${WORKER_NODE}" project- 2>/dev/null || echo "Label already removed."

  echo ""
  echo "=========================================================="
  echo ">>> Step 4: Verifying Removal on ${WORKER_NODE}"
  echo "=========================================================="
  kubectl describe node "${WORKER_NODE}" | grep -E "Labels:|Taints:" -A 3
fi

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Lab 10 resources cleaned up successfully!"
echo "=========================================================="
