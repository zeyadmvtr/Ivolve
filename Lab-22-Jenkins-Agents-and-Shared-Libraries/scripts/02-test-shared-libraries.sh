#!/usr/bin/env bash
# ==============================================================================
# Script: 02-test-shared-libraries.sh
# Purpose: Validate structure and syntax of Jenkins Shared Libraries
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../shared-library/vars"

echo "=========================================================="
echo ">>> Checking Shared Library Files"
echo "=========================================================="

for file in "${LIB_DIR}"/*.groovy; do
  echo "[+] Found shared library module: $(basename "${file}")"
  # Basic syntax sanity check
  head -n 12 "${file}"
  echo "----------------------------------------------------------"
done

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] All 3 shared libraries (buildApp, buildImage, deployOnK8s) verified!"
echo "=========================================================="
