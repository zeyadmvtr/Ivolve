#!/usr/bin/env bash
# ==============================================================================
# Script: 01-setup-rbac.sh
# Purpose: Create ServiceAccount 'jenkinsSA', token, 'ivolveDeployRole', & 'ivolveDeployRoleBinding'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Ensuring 'ivolve' Namespace Exists"
echo "=========================================================="
kubectl get namespace ivolve >/dev/null 2>&1 || kubectl create namespace ivolve

echo ""
echo "=========================================================="
echo ">>> Step 2: Creating Service Account 'jenkinsSA' & Token"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-service-account.yaml"
kubectl apply -f "${MANIFESTS_DIR}/02-service-account-token.yaml"

echo ""
echo ">>> Verifying Service Account:"
kubectl get sa jenkinsSA -n ivolve -o wide

echo ""
echo "=========================================================="
echo ">>> Step 3: Applying Role 'ivolveDeployRole'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-role.yaml"
kubectl describe role ivolveDeployRole -n ivolve

echo ""
echo "=========================================================="
echo ">>> Step 4: Applying RoleBinding 'ivolveDeployRoleBinding'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/04-rolebinding.yaml"
kubectl describe rolebinding ivolveDeployRoleBinding -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] RBAC setup for jenkinsSA completed!"
echo "=========================================================="
