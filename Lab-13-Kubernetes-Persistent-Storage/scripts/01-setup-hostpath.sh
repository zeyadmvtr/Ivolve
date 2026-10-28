#!/usr/bin/env bash
# ==============================================================================
# Script: 01-setup-hostpath.sh
# Purpose: Prepare hostPath directory /mnt/app-logs on the Kubernetes node
# Target: Run on worker/target node with sudo privileges
# ==============================================================================

set -euo pipefail

LOG_DIR="/mnt/app-logs"

echo "=========================================================="
echo ">>> Creating hostPath directory: ${LOG_DIR}"
echo "=========================================================="

sudo mkdir -p "${LOG_DIR}"
sudo chmod 777 "${LOG_DIR}"

echo ""
echo ">>> Directory status:"
ls -ld "${LOG_DIR}"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Host directory ${LOG_DIR} prepared with ReadWriteMany permissions!"
echo "=========================================================="
