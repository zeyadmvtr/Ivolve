#!/usr/bin/env bash
# ==============================================================================
# Script: 02-test-traffic-isolation.sh
# Purpose: Validate that ivolveNP allows application pods and blocks unauthorized pods
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Test 1: Testing Traffic from AUTHORIZED Application Pods"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-authorized-client-pod.yaml"
kubectl wait --for=condition=Ready pod/authorized-app-client -n ivolve --timeout=60s

echo ">>> Inspecting connection test from authorized pod:"
kubectl logs -n ivolve authorized-app-client

echo ""
echo "=========================================================="
echo ">>> Test 2: Testing Traffic from UNAUTHORIZED Pod (Negative Test)"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-unauthorized-client-pod.yaml"
kubectl wait --for=condition=Ready pod/unauthorized-rogue-client -n ivolve --timeout=60s

echo ">>> Inspecting connection test from unauthorized pod:"
kubectl logs -n ivolve unauthorized-rogue-client

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] NetworkPolicy traffic isolation confirmed!"
echo ">>> - Authorized traffic (app: ivolve-app) -> MySQL:3306 [ALLOWED]"
echo ">>> - Unauthorized traffic -> MySQL:3306 [BLOCKED / TIMEOUT]"
echo "=========================================================="
