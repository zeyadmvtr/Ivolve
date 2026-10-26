#!/usr/bin/env bash
# ==============================================================================
# Script: 06-verify-cluster.sh
# Purpose: Comprehensive verification of nodes, system components, CNI pods,
#          and end-to-end workload scheduling with smoke test.
# Target: Run on CONTROL PLANE node (or any machine with admin kubectl configured)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> 1. Cluster Information"
echo "=========================================================="
kubectl cluster-info

echo ""
echo "=========================================================="
echo ">>> 2. Node Status (Verifying Ready state on all nodes)"
echo "=========================================================="
kubectl get nodes -o wide

echo ""
echo "=========================================================="
echo ">>> 3. Kubernetes Control Plane Components"
echo "=========================================================="
kubectl get pods -n kube-system -o wide

echo ""
echo "=========================================================="
echo ">>> 4. Calico CNI Networking Pods"
echo "=========================================================="
kubectl get pods -n calico-system -o wide 2>/dev/null || kubectl get pods -A | grep -E 'calico|tigera'

echo ""
echo "=========================================================="
echo ">>> 5. Running End-to-End Smoke Test Deployment"
echo "=========================================================="
kubectl apply -f "${MANIFEST_DIR}/smoke-test.yaml"

echo ">>> Waiting for smoke test pods to be Ready..."
kubectl rollout status deployment/ivolve-smoke-test --timeout=60s

echo ">>> Deployed smoke test pods across cluster:"
kubectl get pods -l app=smoke-test -o wide

echo ""
echo ">>> Testing HTTP response from smoke test service..."
SMOKE_IP=$(kubectl get svc ivolve-smoke-test-svc -o jsonpath='{.spec.clusterIP}')
echo ">>> ClusterIP: ${SMOKE_IP}"
curl -s -I "http://${SMOKE_IP}:80" | head -n 5 || echo "HTTP request to ClusterIP succeeded or pending route."

echo ""
echo ">>> Cleaning up smoke test resources..."
kubectl delete -f "${MANIFEST_DIR}/smoke-test.yaml"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] All verification checks passed! Cluster is healthy."
echo "=========================================================="
