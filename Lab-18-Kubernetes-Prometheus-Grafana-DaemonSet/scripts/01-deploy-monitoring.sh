#!/usr/bin/env bash
# ==============================================================================
# Script: 01-deploy-monitoring.sh
# Purpose: Deploy Prometheus, Alertmanager, Grafana, and Node Exporter DaemonSet
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Creating 'monitoring' Namespace"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-monitoring-namespace.yaml"

echo ""
echo "=========================================================="
echo ">>> Step 2: Deploying Node Exporter DaemonSet"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-node-exporter-daemonset.yaml"
kubectl apply -f "${MANIFESTS_DIR}/03-node-exporter-service.yaml"

echo ""
echo "=========================================================="
echo ">>> Step 3: Deploying Prometheus Server & Alertmanager"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/04-prometheus-configmap.yaml"
kubectl apply -f "${MANIFESTS_DIR}/05-prometheus-deployment-and-service.yaml"
kubectl apply -f "${MANIFESTS_DIR}/06-alertmanager-deployment-and-service.yaml"

echo ""
echo "=========================================================="
echo ">>> Step 4: Deploying Grafana with Auto-Provisioned Datasource"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/07-grafana-datasource-and-dashboards.yaml"
kubectl apply -f "${MANIFESTS_DIR}/08-grafana-deployment-and-service.yaml"

echo ""
echo ">>> Waiting for monitoring workloads to roll out..."
kubectl rollout status daemonset/node-exporter -n monitoring --timeout=120s
kubectl rollout status deployment/prometheus -n monitoring --timeout=120s
kubectl rollout status deployment/alertmanager -n monitoring --timeout=120s
kubectl rollout status deployment/grafana -n monitoring --timeout=120s

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Full Monitoring Stack deployed successfully!"
echo "=========================================================="
kubectl get all -n monitoring
