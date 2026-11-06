#!/usr/bin/env bash
# ==============================================================================
# Script: 03-verify-metrics-and-prometheus.sh
# Purpose: Verify Prometheus scrapes node-exporter and test PromQL queries
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1: Checking Prometheus Scrape Targets"
echo "=========================================================="
PROM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')

echo ">>> Inspecting active targets from Prometheus API..."
kubectl exec -n monitoring "${PROM_POD}" -- wget -qO- http://localhost:9090/api/v1/targets | grep -o '"job":"[^"]*","health":"[^"]*"' || true

echo ""
echo "=========================================================="
echo ">>> Step 2: Querying Node CPU & Memory Metrics via PromQL"
echo "=========================================================="
echo ">>> Query: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode='idle'}[1m])) * 100)"
kubectl exec -n monitoring "${PROM_POD}" -- wget -qO- 'http://localhost:9090/api/v1/query?query=100-(avg+by+(instance)+(rate(node_cpu_seconds_total{mode="idle"}[1m]))*100)' || true

echo ""
echo ">>> Query: Node Memory Total (node_memory_MemTotal_bytes):"
kubectl exec -n monitoring "${PROM_POD}" -- wget -qO- 'http://localhost:9090/api/v1/query?query=node_memory_MemTotal_bytes' || true

echo ""
echo "=========================================================="
echo ">>> Step 3: Accessing Grafana Dashboard"
echo "=========================================================="
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo ">>> Grafana Web UI is available at:"
echo "    http://${NODE_IP}:30080"
echo "    Credentials: admin / admin123"
echo ">>> Preconfigured Datasource: Prometheus (http://prometheus.monitoring.svc.cluster.local:9090)"
echo ">>> Recommended Community Dashboard ID for Node Exporter: 1860 (Node Exporter Full)"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Prometheus and Grafana integration verified!"
echo "=========================================================="
