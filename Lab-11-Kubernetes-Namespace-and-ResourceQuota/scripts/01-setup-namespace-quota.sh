#!/usr/bin/env bash
# ==============================================================================
# Script: 01-setup-namespace-quota.sh
# Purpose: Create Kubernetes namespace 'ivolve' and apply ResourceQuota 'ivolveQuota'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Creating 'ivolve' Namespace"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-namespace.yaml"

echo ""
echo ">>> Verifying Namespace creation:"
kubectl get namespace ivolve --show-labels

echo ""
echo "=========================================================="
echo ">>> Step 2: Applying ResourceQuota 'ivolveQuota'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-resource-quota.yaml"

echo ""
echo ">>> Verifying ResourceQuota in 'ivolve' namespace:"
kubectl get resourcequota -n ivolve
echo ""
kubectl describe resourcequota ivolveQuota -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Namespace 'ivolve' and ResourceQuota 'ivolveQuota' configured!"
echo "=========================================================="
