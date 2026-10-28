#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Delete test workloads or persistent storage resources
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing test logging pods and deployments"
echo "=========================================================="

kubectl delete -f "${MANIFESTS_DIR}/03-logging-deployment.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/04-log-reader-pod.yaml" --ignore-not-found=true

echo ""
echo ">>> Logging workloads removed."
echo ""
echo "=========================================================="
echo ">>> Note: To delete the PVC and PV, run:"
echo "    kubectl delete -f ${MANIFESTS_DIR}/02-persistent-volume-claim.yaml"
echo "    kubectl delete -f ${MANIFESTS_DIR}/01-persistent-volume.yaml"
echo "=========================================================="
