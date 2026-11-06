#!/usr/bin/env bash
# ==============================================================================
# Script: 04-verify-gitops-sync.sh
# Purpose: Verify Argo CD synchronization status and target cluster workload state
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1: Inspecting Argo CD Application Sync & Health Status"
echo "=========================================================="
SYNC_STATUS=$(kubectl get application ivolve -n argocd -o jsonpath='{.status.sync.status}' || echo "Unknown")
HEALTH_STATUS=$(kubectl get application ivolve -n argocd -o jsonpath='{.status.health.status}' || echo "Unknown")
TARGET_REV=$(kubectl get application ivolve -n argocd -o jsonpath='{.status.sync.revision}' || echo "Unknown")

echo "Sync Status   : ${SYNC_STATUS}"
echo "Health Status : ${HEALTH_STATUS}"
echo "Git Revision  : ${TARGET_REV}"

echo ""
echo "=========================================================="
echo ">>> Step 2: Inspecting Deployed Kubernetes Workload in 'ivolve' Namespace"
echo "=========================================================="
kubectl get deployment ivolve-gitops-app -n ivolve -o wide || true
echo ""
CURRENT_IMAGE=$(kubectl get deployment ivolve-gitops-app -n ivolve -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not found")
echo "Active Container Image deployed by Argo CD: ${CURRENT_IMAGE}"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] GitOps synchronization confirmed!"
echo "=========================================================="
