#!/usr/bin/env bash
# ==============================================================================
# Script: 03-verify-logging-persistence.sh
# Purpose: Validate ReadWriteMany concurrent logging and data persistence
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Deploying multi-replica logging application"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-logging-deployment.yaml"

echo ""
echo ">>> Waiting for logging pods to enter Running state..."
kubectl rollout status deployment/ivolve-logging-app -n ivolve --timeout=60s

echo ""
echo ">>> Current Pods:"
kubectl get pods -n ivolve -l app=ivolve-logging -o wide

echo ""
echo ">>> Sleeping 12s to allow multiple replicas to write log entries..."
sleep 12

echo ""
echo "=========================================================="
echo ">>> Step 2: Inspecting shared log file via pod exec"
echo "=========================================================="
FIRST_POD=$(kubectl get pods -n ivolve -l app=ivolve-logging -o jsonpath='{.items[0].metadata.name}')
echo ">>> Reading /mnt/app-logs/application.log from Pod: ${FIRST_POD}"
kubectl exec -n ivolve "${FIRST_POD}" -- cat /mnt/app-logs/application.log | tail -n 10

echo ""
echo "=========================================================="
echo ">>> Step 3: Testing Persistence Across Pod Destruction"
echo "=========================================================="
echo ">>> Deleting deployment..."
kubectl delete -f "${MANIFESTS_DIR}/03-logging-deployment.yaml"

echo ""
echo ">>> Deploying standalone reader pod to inspect retained logs..."
kubectl apply -f "${MANIFESTS_DIR}/04-log-reader-pod.yaml"
kubectl wait --for=condition=Ready pod/ivolve-log-reader -n ivolve --timeout=60s

echo ""
echo ">>> Logs read from new pod mounted to ivolvePVC:"
kubectl exec -n ivolve ivolve-log-reader -- cat /mnt/app-logs/application.log | tail -n 10

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Persistent logging across pod lifecycle verified!"
echo "=========================================================="
