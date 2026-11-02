#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Clean up test pods or full ivolveApp deployment
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing test pods (manual-mysql-verify, ivolve-client-tester)"
echo "=========================================================="
kubectl delete pod manual-mysql-verify ivolve-client-tester -n ivolve --ignore-not-found=true

echo ""
echo "=========================================================="
echo ">>> Note: Deployment 'ivolveApp' and Service 'ivolveAppSvc' are kept"
echo "    active for use by Lab 16 and Lab 17."
echo "    To delete them completely, run:"
echo "    kubectl delete -f ${MANIFESTS_DIR}/02-deployment.yaml"
echo "    kubectl delete -f ${MANIFESTS_DIR}/01-clusterip-service.yaml"
echo "=========================================================="
