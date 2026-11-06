#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Clean up RBAC resources created for jenkinsSA
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Cleaning up jenkinsSA RBAC resources in 'ivolve' namespace"
echo "=========================================================="

kubectl delete -f "${MANIFESTS_DIR}/04-rolebinding.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/03-role.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/02-service-account-token.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/01-service-account.yaml" --ignore-not-found=true
rm -f jenkins-kubeconfig.yaml

echo ""
echo ">>> [SUCCESS] RBAC cleanup complete."
