#!/usr/bin/env bash
# ==============================================================================
# Script: 02-apply-storage.sh
# Purpose: Apply PersistentVolume 'ivolvePV' and PersistentVolumeClaim 'ivolvePVC'
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Applying PersistentVolume 'ivolvePV' (Cluster-Scoped)"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/01-persistent-volume.yaml"

echo ""
echo ">>> Describing PersistentVolume 'ivolvePV':"
kubectl describe pv ivolvePV

echo ""
echo "=========================================================="
echo ">>> Step 2: Applying PersistentVolumeClaim 'ivolvePVC' (in 'ivolve' ns)"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/02-persistent-volume-claim.yaml"

echo ""
echo ">>> Waiting for PVC to bind..."
sleep 2

echo ""
echo ">>> Verifying PV and PVC Binding Status:"
kubectl get pv ivolvePV
echo ""
kubectl get pvc ivolvePVC -n ivolve

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] PersistentVolume and Claim successfully bound!"
echo "=========================================================="
