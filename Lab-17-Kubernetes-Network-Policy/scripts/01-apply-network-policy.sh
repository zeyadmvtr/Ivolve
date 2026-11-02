#!/usr/bin/env bash
# ==============================================================================
# Script: 01-apply-network-policy.sh
# Purpose: Apply NetworkPolicy 'ivolveNP' to control ingress traffic to MySQL
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Applying NetworkPolicy 'ivolveNP'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-network-policy.yaml"

echo ""
echo ">>> Listing NetworkPolicies in 'ivolve' namespace:"
kubectl get networkpolicy -n ivolve -o wide

echo ""
echo "=========================================================="
echo ">>> Step 2: Describing 'ivolveNP'"
echo "=========================================================="
kubectl describe networkpolicy ivolveNP -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] NetworkPolicy 'ivolveNP' applied successfully!"
echo "=========================================================="
