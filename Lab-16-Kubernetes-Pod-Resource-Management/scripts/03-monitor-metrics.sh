#!/usr/bin/env bash
# ==============================================================================
# Script: 03-monitor-metrics.sh
# Purpose: Monitor real-time CPU and Memory usage via kubectl top pod
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Checking if Metrics Server is Operational"
echo "=========================================================="
if ! kubectl top nodes >/dev/null 2>&1; then
  echo "[-] Metrics Server API is not responding or not installed."
  echo ">>> Attempting to install Metrics Server from manifests/04-metrics-server.yaml..."
  kubectl apply -f "${MANIFESTS_DIR}/04-metrics-server.yaml"
  echo ">>> Waiting 30s for Metrics Server pods and scraping cycle..."
  sleep 30
else
  echo "[+] Metrics Server is operational."
fi

echo ""
echo "=========================================================="
echo ">>> Step 2: Generating Load via ivolve-load-generator"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-load-generator.yaml"
echo ">>> Load generator active. Collecting real-time metrics..."

sleep 5

echo ""
echo "=========================================================="
echo ">>> Step 3: Real-Time Resource Usage via kubectl top pod"
echo "=========================================================="
echo ">>> Monitoring pods in namespace 'ivolve':"
kubectl top pod -n ivolve --containers=true || kubectl top pod -n ivolve || true

echo ""
echo ">>> Monitoring all cluster pods:"
kubectl top pods -A || true

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] kubectl top pod monitoring executed successfully!"
echo "=========================================================="
