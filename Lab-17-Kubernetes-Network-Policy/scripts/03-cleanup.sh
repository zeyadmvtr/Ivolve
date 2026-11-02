#!/usr/bin/env bash
# ==============================================================================
# Script: 03-cleanup.sh
# Purpose: Delete test verification pods or NetworkPolicy
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing test verification pods"
echo "=========================================================="
kubectl delete pod authorized-app-client unauthorized-rogue-client -n ivolve --ignore-not-found=true

echo ""
echo ">>> Test pods removed."
echo ""
echo "=========================================================="
echo ">>> Note: NetworkPolicy 'ivolveNP' is preserved."
echo "    To delete it completely, run:"
echo "    kubectl delete -f ${MANIFESTS_DIR}/01-network-policy.yaml"
echo "=========================================================="
