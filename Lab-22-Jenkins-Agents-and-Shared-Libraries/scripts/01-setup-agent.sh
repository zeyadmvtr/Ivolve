#!/usr/bin/env bash
# ==============================================================================
# Script: 01-setup-agent.sh
# Purpose: Build and launch Jenkins SSH Slave Agent container labeled 'slave-node'
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/../agent-setup"

echo "=========================================================="
echo ">>> Building and starting Jenkins Slave Node container..."
echo "=========================================================="

docker compose -f docker-compose.agent.yml up -d --build

echo ""
echo ">>> Checking slave agent container status:"
docker ps --filter "name=jenkins-slave-node"

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Jenkins Slave Agent is active on port 2222!"
echo ">>> Connect from Jenkins Controller via SSH or JNLP"
echo ">>> Label to assign in Jenkins Node configuration: 'slave-node'"
echo "=========================================================="
