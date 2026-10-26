#!/usr/bin/env bash
# ==============================================================================
# Script: 04-install-calico.sh
# Purpose: Install and configure Calico CNI plugin for pod networking.
# Target: Run on CONTROL PLANE node ONLY after kubectl is configured
# ==============================================================================

set -euo pipefail

CALICO_VERSION="${CALICO_VERSION:-v3.28.2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 4.1: Installing Tigera Calico Operator (${CALICO_VERSION})"
echo "=========================================================="
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml" || true

echo "=========================================================="
echo ">>> Step 4.2: Applying Calico Custom Resources (CIDR: 192.168.0.0/16)"
echo "=========================================================="
if [ -f "${MANIFEST_DIR}/calico-custom-resources.yaml" ]; then
  kubectl apply -f "${MANIFEST_DIR}/calico-custom-resources.yaml"
else
  kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml"
fi

echo "=========================================================="
echo ">>> Step 4.3: Waiting for Calico System Pods to Start"
echo "=========================================================="
echo ">>> Checking tigera-operator status..."
kubectl rollout status deployment/tigera-operator -n tigera-operator --timeout=120s

echo ">>> Calico pods deployment initiated. Checking pods in calico-system / kube-system:"
sleep 5
kubectl get pods -A | grep -E 'calico|tigera' || true

echo "=========================================================="
echo ">>> [SUCCESS] Calico CNI plugin installed successfully!"
echo "=========================================================="
