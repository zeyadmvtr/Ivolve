#!/usr/bin/env bash
# ==============================================================================
# Script: 01-deploy-statefulset.sh
# Purpose: Deploy MySQL StatefulSet 'ivolveDB' with headless service 'ivolveDBSvc'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"
LAB12_MANIFESTS="${SCRIPT_DIR}/../../Lab-12-Kubernetes-ConfigMaps-and-Secrets/manifests"

echo "=========================================================="
echo ">>> Step 1: Validating Prerequisites"
echo "=========================================================="

# Ensure namespace exists
kubectl get namespace ivolve >/dev/null 2>&1 || kubectl create namespace ivolve

# Ensure ConfigMap and Secret from Lab 12 exist
if ! kubectl get configmap ivolveCM -n ivolve >/dev/null 2>&1; then
  echo ">>> ConfigMap ivolveCM not found. Applying from Lab 12..."
  kubectl apply -f "${LAB12_MANIFESTS}/01-configmap.yaml"
fi

if ! kubectl get secret ivolveSecret -n ivolve >/dev/null 2>&1; then
  echo ">>> Secret ivolveSecret not found. Applying from Lab 12..."
  kubectl apply -f "${LAB12_MANIFESTS}/02-secret.yaml"
fi

# Ensure PV exists if dynamic provisioner is absent
if ! kubectl get pv mysql-data-pv >/dev/null 2>&1; then
  echo ">>> Provisioning local PersistentVolume for StatefulSet..."
  kubectl apply -f "${MANIFESTS_DIR}/00-mysql-pv.yaml"
fi

echo ""
echo "=========================================================="
echo ">>> Step 2: Applying Headless Service 'ivolveDBSvc'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-headless-service.yaml"

echo ""
echo ">>> Verifying Headless Service:"
kubectl get svc ivolveDBSvc -n ivolve -o wide

echo ""
echo "=========================================================="
echo ">>> Step 3: Deploying StatefulSet 'ivolveDB'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-statefulset.yaml"

echo ""
echo ">>> Waiting for StatefulSet pod 'ivolveDB-0' to initialize..."
kubectl rollout status statefulset/ivolveDB -n ivolve --timeout=180s

echo ""
echo "=========================================================="
echo ">>> Step 4: Inspecting StatefulSet Pod and Node Placement"
echo "=========================================================="
kubectl get statefulset ivolveDB -n ivolve
echo ""
kubectl get pods -n ivolve -l app=ivolve-db -o wide

echo ""
echo ">>> Verifying Bound PersistentVolumeClaim:"
kubectl get pvc -n ivolve -l app.kubernetes.io/name=ivolve-db || kubectl get pvc -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] MySQL StatefulSet and Headless Service running!"
echo "=========================================================="
