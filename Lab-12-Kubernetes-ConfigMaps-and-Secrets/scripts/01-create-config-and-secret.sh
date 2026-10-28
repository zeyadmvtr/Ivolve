#!/usr/bin/env bash
# ==============================================================================
# Script: 01-create-config-and-secret.sh
# Purpose: Generate Base64 credentials and apply ivolveCM and ivolveSecret
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Base64 Encoding Demonstration"
echo "=========================================================="
RAW_ROOT_PW="ivolveRootPass2026!"
RAW_USER_PW="ivolveUserPass2026!"

ENCODED_ROOT_PW=$(echo -n "${RAW_ROOT_PW}" | base64)
ENCODED_USER_PW=$(echo -n "${RAW_USER_PW}" | base64)

echo "Plaintext MYSQL_ROOT_PASSWORD : ${RAW_ROOT_PW}"
echo "Base64 Encoded                : ${ENCODED_ROOT_PW}"
echo "----------------------------------------------------------"
echo "Plaintext DB_PASSWORD         : ${RAW_USER_PW}"
echo "Base64 Encoded                : ${ENCODED_USER_PW}"

echo ""
echo "=========================================================="
echo ">>> Step 2: Ensuring 'ivolve' Namespace Exists"
echo "=========================================================="
kubectl get namespace ivolve >/dev/null 2>&1 || kubectl create namespace ivolve

echo ""
echo "=========================================================="
echo ">>> Step 3: Applying ConfigMap 'ivolveCM'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-configmap.yaml"

echo ""
echo ">>> Describing ConfigMap 'ivolveCM':"
kubectl describe configmap ivolveCM -n ivolve

echo ""
echo "=========================================================="
echo ">>> Step 4: Applying Secret 'ivolveSecret'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-secret.yaml"

echo ""
echo ">>> Describing Secret 'ivolveSecret' (data keys are masked for security):"
kubectl describe secret ivolveSecret -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] ConfigMap and Secret applied successfully!"
echo "=========================================================="
