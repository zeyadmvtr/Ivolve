#!/usr/bin/env bash
# ==============================================================================
# Script: 05-cleanup.sh
# Purpose: Delete Argo CD Application and remove Argo CD components
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing Argo CD Application 'ivolve'..."
echo "=========================================================="
kubectl delete -f "${MANIFESTS_DIR}/03-argocd-application-ivolve.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/02-argocd-repo-secret.yaml" --ignore-not-found=true

echo ""
echo "=========================================================="
echo ">>> Note: To completely delete Argo CD namespace and operator, run:"
echo "    kubectl delete namespace argocd"
echo "=========================================================="
