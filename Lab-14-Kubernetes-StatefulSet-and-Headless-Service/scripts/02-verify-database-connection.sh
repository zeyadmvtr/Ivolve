#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-database-connection.sh
# Purpose: Confirm MySQL database is operational by executing client queries
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Step 1: Internal Database Health Check via Pod Exec"
echo "=========================================================="

echo ">>> Checking MySQL server status inside ivolveDB-0..."
kubectl exec -n ivolve ivolveDB-0 -- mysqladmin -u root -p"ivolveRootPass2026!" ping

echo ""
echo ">>> Listing databases inside ivolveDB-0:"
kubectl exec -n ivolve ivolveDB-0 -- mysql -u root -p"ivolveRootPass2026!" -e "SHOW DATABASES;"

echo ""
echo "=========================================================="
echo ">>> Step 2: Testing Application User Authentication ('ivolveuser')"
echo "=========================================================="
kubectl exec -n ivolve ivolveDB-0 -- mysql -u ivolveuser -p"ivolveUserPass2026!" -D ivolve -e "
  SELECT USER(), CURRENT_USER(), DATABASE(), VERSION();
"

echo ""
echo "=========================================================="
echo ">>> Step 3: End-to-End Client Pod Query via Headless Service DNS"
echo "=========================================================="
echo ">>> Deploying client verification pod..."
kubectl apply -f "${MANIFESTS_DIR}/03-mysql-client-test-pod.yaml"

echo ">>> Waiting for client pod to execute..."
kubectl wait --for=condition=Ready pod/mysql-client-test -n ivolve --timeout=90s

echo ""
echo ">>> Logs from client test pod:"
kubectl logs -n ivolve mysql-client-test

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] MySQL database operational and client connection verified!"
echo "=========================================================="
