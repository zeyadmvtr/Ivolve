#!/usr/bin/env bash
# ==============================================================================
# Script: 03-cleanup.sh
# Purpose: Delete test workloads or clean up the 'ivolve' namespace
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Cleaning up test workloads in 'ivolve' namespace"
echo "=========================================================="

kubectl delete deployment quota-test-workload -n ivolve --ignore-not-found=true
kubectl delete pod extra-test-pod -n ivolve --ignore-not-found=true

echo ""
echo ">>> Test workloads removed. Current pods in 'ivolve':"
kubectl get pods -n ivolve

echo ""
echo "=========================================================="
echo ">>> Note: To completely delete the 'ivolve' namespace and quota, run:"
echo "    kubectl delete namespace ivolve"
echo "=========================================================="
