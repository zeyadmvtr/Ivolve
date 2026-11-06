#!/usr/bin/env bash
# ==============================================================================
# Script: 03-cleanup.sh
# Purpose: Stop Jenkins container and remove test volumes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo ">>> Stopping Jenkins container..."
docker compose down -v --remove-orphans

echo "[+] Cleanup complete."
