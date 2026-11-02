#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-resources.sh
# Purpose: Verify applied resource requests and limits using kubectl describe pod
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1: Listing Current ivolveApp Pods"
echo "=========================================================="
kubectl get pods -n ivolve -l app=ivolve-app -o wide

echo ""
echo "=========================================================="
echo ">>> Step 2: Describing Pods and Extracting Requests/Limits"
echo "=========================================================="
PODS=$(kubectl get pods -n ivolve -l app=ivolve-app -o jsonpath='{.items[*].metadata.name}')

for POD in ${PODS}; do
  echo "----------------------------------------------------------"
  echo ">>> Pod: ${POD}"
  echo "----------------------------------------------------------"
  kubectl describe pod "${POD}" -n ivolve | grep -E "Container ID:|Requests:|Limits:|cpu:|memory:|QoS Class:" -A 3
  echo ""
done

echo "=========================================================="
echo ">>> Step 3: Verifying QoS Class (Quality of Service)"
echo "=========================================================="
FIRST_POD=$(echo "${PODS}" | awk '{print $1}')
QOS=$(kubectl get pod "${FIRST_POD}" -n ivolve -o jsonpath='{.status.qosClass}')
echo "Pod QoS Class: ${QOS}"
echo "(Expected: Burstable, because Requests < Limits)"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Resource requests and limits verified via kubectl describe pod!"
echo "=========================================================="
