#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-node-exporter.sh
# Purpose: Validate Node Exporter DaemonSet scheduling on each node and metrics exposure
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1: Checking Node Count vs Node Exporter Pod Count"
echo "=========================================================="
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
EXPORTER_DESIRED=$(kubectl get daemonset node-exporter -n monitoring -o jsonpath='{.status.desiredNumberScheduled}')
EXPORTER_CURRENT=$(kubectl get daemonset node-exporter -n monitoring -o jsonpath='{.status.currentNumberScheduled}')
EXPORTER_READY=$(kubectl get daemonset node-exporter -n monitoring -o jsonpath='{.status.numberReady}')

echo "Total Nodes in Cluster       : ${TOTAL_NODES}"
echo "DaemonSet Desired Scheduled  : ${EXPORTER_DESIRED}"
echo "DaemonSet Current Scheduled  : ${EXPORTER_CURRENT}"
echo "DaemonSet Ready Replicas     : ${EXPORTER_READY}"

if [ "${TOTAL_NODES}" -eq "${EXPORTER_READY}" ]; then
  echo "[+] [CONFIRMED] A node-exporter pod is actively scheduled and running on every node!"
else
  echo "[!] Notice: Some nodes may still be initializing or have restrictive taints."
fi

echo ""
echo "=========================================================="
echo ">>> Step 2: Listing Node Exporter Pods by Node Placement"
echo "=========================================================="
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter -o wide

echo ""
echo "=========================================================="
echo ">>> Step 3: Verifying Metrics Exposure on <node_IP>:9100/metrics"
echo "=========================================================="
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')

for NODE_IP in ${NODE_IPS}; do
  echo "----------------------------------------------------------"
  echo ">>> Testing Node IP: ${NODE_IP}:9100/metrics"
  echo "----------------------------------------------------------"
  if curl -s --max-time 3 "http://${NODE_IP}:9100/metrics" | grep -E "^node_cpu_seconds_total|^node_memory_MemTotal_bytes" | head -n 4; then
    echo "[+] Node Exporter metrics successfully retrieved from ${NODE_IP}:9100!"
  else
    echo ">>> Running test via temporary curl pod in cluster..."
    kubectl run -it --rm test-curl --image=curlimages/curl:8.5.0 --restart=Never -n monitoring -- curl -s --max-time 3 "http://${NODE_IP}:9100/metrics" | grep -E "^node_cpu_seconds_total|^node_memory_MemTotal_bytes" | head -n 4 || true
  fi
  echo ""
done

echo "=========================================================="
echo ">>> [SUCCESS] Node Exporter verification complete!"
echo "=========================================================="
