#!/usr/bin/env bash
# ==============================================================================
# Script: 03-create-argocd-app.sh
# Purpose: Connect GitHub repo and create 'ivolve' Argo CD Application with auto-sync
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Connecting Repository to Argo CD"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-argocd-repo-secret.yaml"

echo ""
echo "=========================================================="
echo ">>> Step 2: Creating Argo CD Application 'ivolve'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-argocd-application-ivolve.yaml"

echo ""
echo ">>> Waiting for initial synchronization..."
sleep 8

echo ""
echo "=========================================================="
echo ">>> Step 3: Checking Application Status"
echo "=========================================================="
kubectl get application ivolve -n argocd -o wide

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Argo CD Application 'ivolve' successfully created!"
echo "=========================================================="
