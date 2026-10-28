#!/usr/bin/env bash
# ==============================================================================
# Script: 03-cleanup.sh
# Purpose: Delete test consumer pod or all Lab 12 configuration resources
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing test consumer pod"
echo "=========================================================="
kubectl delete pod ivolve-config-consumer -n ivolve --ignore-not-found=true

echo ""
echo ">>> Consumer pod removed."
echo ""
echo "=========================================================="
echo ">>> Note: ConfigMap 'ivolveCM' and Secret 'ivolveSecret' are preserved"
echo "    for use by downstream labs (Lab 14 StatefulSet)."
echo "    To delete them completely, run:"
echo "    kubectl delete configmap ivolveCM -n ivolve"
echo "    kubectl delete secret ivolveSecret -n ivolve"
echo "=========================================================="
