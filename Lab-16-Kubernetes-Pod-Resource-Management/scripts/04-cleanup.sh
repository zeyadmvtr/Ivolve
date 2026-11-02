#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Clean up load generator job/pod in namespace 'ivolve'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing load generator job and pods"
echo "=========================================================="
kubectl delete job ivolve-load-generator -n ivolve --ignore-not-found=true

echo ""
echo ">>> Load generator removed. Deployment ivolveApp remains active."
echo "=========================================================="
