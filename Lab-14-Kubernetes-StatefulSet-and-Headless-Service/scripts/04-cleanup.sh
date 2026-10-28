#!/usr/bin/env bash
# ==============================================================================
# Script: 04-cleanup.sh
# Purpose: Delete StatefulSet, Headless Service, test pods and persistent claims
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Removing test pods (mysql-client-test, dnsutils)"
echo "=========================================================="
kubectl delete pod mysql-client-test dnsutils -n ivolve --ignore-not-found=true

echo ""
echo "=========================================================="
echo ">>> Deleting StatefulSet 'ivolveDB' and Service 'ivolveDBSvc'"
echo "=========================================================="
kubectl delete -f "${MANIFESTS_DIR}/02-statefulset.yaml" --ignore-not-found=true
kubectl delete -f "${MANIFESTS_DIR}/01-headless-service.yaml" --ignore-not-found=true

echo ""
echo "=========================================================="
echo ">>> Note: In Kubernetes, StatefulSet PVC templates are intentionally"
echo "    NOT automatically deleted to protect stateful data."
echo "    To remove the PVC and PV, run:"
echo "    kubectl delete pvc mysql-data-ivolveDB-0 -n ivolve"
echo "    kubectl delete pv mysql-data-pv"
echo "=========================================================="
