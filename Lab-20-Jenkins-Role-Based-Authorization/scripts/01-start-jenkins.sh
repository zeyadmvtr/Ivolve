#!/usr/bin/env bash
# ==============================================================================
# Script: 01-start-jenkins.sh
# Purpose: Start Jenkins container with Role-Based Authorization preconfigured
# Target: Any Docker-enabled host
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "=========================================================="
echo ">>> Starting Jenkins with Role-Based Strategy..."
echo "=========================================================="

docker compose up -d

echo ""
echo ">>> Waiting for Jenkins to initialize on http://localhost:8080..."
until curl -s http://localhost:8080/login > /dev/null; do
  echo "Still waiting for Jenkins startup..."
  sleep 5
done

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Jenkins is UP and configured!"
echo ">>> Web URL: http://localhost:8080"
echo ">>> Users:"
echo "    - user1 (admin)     : user1Pass2026!"
echo "    - user2 (read-only) : user2Pass2026!"
echo "=========================================================="
