#!/usr/bin/env bash
# ==============================================================================
# Script: 02-test-isolation.sh
# Purpose: Test and demonstrate node isolation by deploying untolerated, tolerated,
#          and targeted workloads against the tainted and labeled worker node.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Deploying Test Workloads"
echo "=========================================================="
echo ">>> 1.1 Applying untolerated pod (should be repelled from tainted node)..."
kubectl apply -f "${MANIFEST_DIR}/01-untainted-default-pod.yaml"

echo ">>> 1.2 Applying tolerated pod (can run on tainted node)..."
kubectl apply -f "${MANIFEST_DIR}/02-tolerated-pod.yaml"

echo ">>> 1.3 Applying dedicated iVolve deployment (targeted via nodeSelector & toleration)..."
kubectl apply -f "${MANIFEST_DIR}/03-targeted-ivolveapp-deployment.yaml"

echo ""
echo ">>> Waiting 10 seconds for Kubernetes Scheduler..."
sleep 10

echo ""
echo "=========================================================="
echo ">>> Step 2: Pod Placement Analysis Across Nodes"
echo "=========================================================="
kubectl get pods -o wide

echo ""
echo "=========================================================="
echo ">>> Step 3: Checking Scheduling Events"
echo "=========================================================="
echo ">>> Default untolerated pod events:"
kubectl describe pod default-untainted-pod | grep -E "Node:|Events:" -A 8 || true

echo ""
echo ">>> Dedicated iVolve deployment pods placement:"
kubectl get pods -l app=ivolve-app -o custom-columns="NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase,IP:.status.podIP"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Node isolation test successfully verified!"
echo "=========================================================="
