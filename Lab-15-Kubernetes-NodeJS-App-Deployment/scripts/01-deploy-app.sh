#!/usr/bin/env bash
# ==============================================================================
# Script: 01-deploy-app.sh
# Purpose: Deploy Node.js ClusterIP Service and Deployment 'ivolveApp'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Checking Prerequisites (Namespace, CM, Secret, PVC, DB)"
echo "=========================================================="

# Ensure namespace exists
kubectl get namespace ivolve >/dev/null 2>&1 || kubectl create namespace ivolve

# Check ConfigMap and Secret
if ! kubectl get configmap ivolveCM -n ivolve >/dev/null 2>&1; then
  echo "[-] ERROR: ConfigMap 'ivolveCM' not found in namespace 'ivolve'. Please apply Lab 12."
  exit 1
fi

if ! kubectl get secret ivolveSecret -n ivolve >/dev/null 2>&1; then
  echo "[-] ERROR: Secret 'ivolveSecret' not found in namespace 'ivolve'. Please apply Lab 12."
  exit 1
fi

if ! kubectl get pvc ivolvePVC -n ivolve >/dev/null 2>&1; then
  echo "[-] ERROR: PVC 'ivolvePVC' not found in namespace 'ivolve'. Please apply Lab 13."
  exit 1
fi

echo "[+] Prerequisites verified successfully."

echo ""
echo "=========================================================="
echo ">>> Step 2: Creating ClusterIP Service 'ivolveAppSvc'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-clusterip-service.yaml"
kubectl get svc ivolveAppSvc -n ivolve -o wide

echo ""
echo "=========================================================="
echo ">>> Step 3: Deploying 'ivolveApp' Deployment (2 replicas)"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-deployment.yaml"

echo ""
echo ">>> Waiting for ivolveApp rollout to complete (init container + app start)..."
kubectl rollout status deployment/ivolveApp -n ivolve --timeout=180s

echo ""
echo "=========================================================="
echo ">>> Step 4: Inspecting Pod Placement and Node Selectors"
echo "=========================================================="
kubectl get pods -n ivolve -l app=ivolve-app -o wide

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] ivolveApp successfully deployed with 2 replicas!"
echo "=========================================================="
