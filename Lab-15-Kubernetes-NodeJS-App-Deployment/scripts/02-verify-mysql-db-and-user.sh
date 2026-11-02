#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-mysql-db-and-user.sh
# Purpose: Manually connect to MySQL to verify database and user privileges
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

echo "=========================================================="
echo ">>> Method 1: Direct Verification via MySQL StatefulSet Pod"
echo "=========================================================="
if kubectl get pod ivolveDB-0 -n ivolve >/dev/null 2>&1; then
  echo ">>> Connecting to MySQL inside ivolveDB-0 as root to verify grants:"
  kubectl exec -n ivolve ivolveDB-0 -- mysql -u root -p"ivolveRootPass2026!" -e "
    SHOW DATABASES LIKE 'ivolve';
    SHOW GRANTS FOR 'ivolveuser'@'%';
  "

  echo ""
  echo ">>> Connecting to MySQL inside ivolveDB-0 as application user 'ivolveuser':"
  kubectl exec -n ivolve ivolveDB-0 -- mysql -u ivolveuser -p"ivolveUserPass2026!" -D ivolve -e "
    SELECT USER(), CURRENT_USER(), DATABASE();
    SHOW TABLES;
  "
fi

echo ""
echo "=========================================================="
echo ">>> Method 2: External Client Pod Connection via Service 'ivolveDBSvc'"
echo "=========================================================="
kubectl apply -f "${MANIFESTS_DIR}/03-manual-mysql-verify-pod.yaml"

echo ">>> Waiting for verification pod to run..."
kubectl wait --for=condition=Ready pod/manual-mysql-verify -n ivolve --timeout=60s

echo ""
echo ">>> Logs from manual-mysql-verify pod:"
kubectl logs -n ivolve manual-mysql-verify

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] MySQL database and user privileges verified!"
echo "=========================================================="
