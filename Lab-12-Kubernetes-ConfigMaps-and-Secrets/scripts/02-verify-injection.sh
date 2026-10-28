#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-injection.sh
# Purpose: Deploy consumer pod and verify ConfigMap & Secret environment injection
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Deploying ConfigMap & Secret Consumer Pod"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-consumer-pod.yaml"

echo ""
echo ">>> Waiting for pod 'ivolve-config-consumer' to be Ready..."
kubectl wait --for=condition=Ready pod/ivolve-config-consumer -n ivolve --timeout=60s

echo ""
echo "=========================================================="
echo ">>> Step 2: Verifying Injected Environment Variables"
echo "=========================================================="
echo ">>> Non-sensitive variables (from ivolveCM):"
kubectl exec -n ivolve ivolve-config-consumer -- env | grep -E "^DB_HOST=|^DB_USER="

echo ""
echo ">>> Sensitive variables (from ivolveSecret - checking presence and decoded values):"
kubectl exec -n ivolve ivolve-config-consumer -- env | grep -E "^MYSQL_ROOT_PASSWORD=|^DB_PASSWORD="

echo ""
echo "=========================================================="
echo ">>> Step 3: Verifying Kubernetes Secret Decryption via API"
echo "=========================================================="
DECODED_ROOT=$(kubectl get secret ivolveSecret -n ivolve -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 --decode)
DECODED_USER=$(kubectl get secret ivolveSecret -n ivolve -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode)

echo "Decoded MYSQL_ROOT_PASSWORD from API: ${DECODED_ROOT}"
echo "Decoded DB_PASSWORD from API         : ${DECODED_USER}"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] ConfigMap and Secret injection verified!"
echo "=========================================================="
