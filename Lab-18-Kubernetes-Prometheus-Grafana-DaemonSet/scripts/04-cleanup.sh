#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Tear down monitoring stack in 'monitoring' namespace
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Tearing down Monitoring Stack"
echo "=========================================================="

kubectl delete -f "${MANIFESTS_DIR}/08-grafana-deployment-and-service.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/07-grafana-datasource-and-dashboards.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/06-alertmanager-deployment-and-service.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/05-prometheus-deployment-and-service.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/04-prometheus-configmap.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/03-node-exporter-service.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/02-node-exporter-daemonset.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/01-monitoring-namespace.yaml" --ignore-not-found=true

echo ""
echo ">>> [SUCCESS] Monitoring namespace and resources cleaned up."
