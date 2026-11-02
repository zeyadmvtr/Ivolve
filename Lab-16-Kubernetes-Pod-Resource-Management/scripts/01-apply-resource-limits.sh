#!/usr/bin/env bash
# ==============================================================================
# Script: 01-apply-resource-limits.sh
# Purpose: Update ivolveApp Deployment with CPU and Memory requests and limits
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Applying Updated Deployment Manifest with Resource Limits"
echo "=========================================================="
echo "Configuring:"
echo "  Requests: CPU: 1 (1 vCPU), Memory: 1Gi"
echo "  Limits:   CPU: 2 (2 vCPUs), Memory: 2Gi"
echo "----------------------------------------------------------"

kubectl apply -f "${MANIFESTS_DIR}/01-ivolveapp-deployment-resources.yaml"

echo ""
echo ">>> Waiting for updated rollout to complete..."
kubectl rollout status deployment/ivolveApp -n ivolve --timeout=180s

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Deployment ivolveApp updated with resource requests and limits!"
echo "=========================================================="
