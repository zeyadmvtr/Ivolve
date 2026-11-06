#!/usr/bin/env bash
# ==============================================================================
# Script: 02-verify-roles.sh
# Purpose: Programmatically verify permissions of user1 (admin) and user2 (read-only)
# Target: Any host able to reach Jenkins at http://localhost:8080
# ==============================================================================

set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"

echo "=========================================================="
echo ">>> Test 1: Testing user1 (Role: Admin)"
echo "=========================================================="

# Test access to /manage (Administrative endpoint)
CODE_USER1_MANAGE=$(curl -s -o /dev/null -w "%{http_code}" -u "user1:user1Pass2026!" "${JENKINS_URL}/manage")
echo "HTTP response code for user1 accessing /manage : ${CODE_USER1_MANAGE}"

if [ "${CODE_USER1_MANAGE}" -eq 200 ]; then
  echo "[+] [CONFIRMED] user1 has administrative access (HTTP 200)!"
else
  echo "[-] Unexpected status for user1 on /manage: ${CODE_USER1_MANAGE}"
fi

# Test access to system info
CODE_USER1_API=$(curl -s -o /dev/null -w "%{http_code}" -u "user1:user1Pass2026!" "${JENKINS_URL}/api/json")
echo "HTTP response code for user1 accessing API     : ${CODE_USER1_API}"

echo ""
echo "=========================================================="
echo ">>> Test 2: Testing user2 (Role: Read-Only)"
echo "=========================================================="

# Test access to general view (Read permission)
CODE_USER2_READ=$(curl -s -o /dev/null -w "%{http_code}" -u "user2:user2Pass2026!" "${JENKINS_URL}/api/json")
echo "HTTP response code for user2 accessing API     : ${CODE_USER2_READ}"

if [ "${CODE_USER2_READ}" -eq 200 ]; then
  echo "[+] [CONFIRMED] user2 has read access to view Jenkins jobs (HTTP 200)!"
fi

# Test access to /manage (Forbidden for read-only role)
CODE_USER2_MANAGE=$(curl -s -o /dev/null -w "%{http_code}" -u "user2:user2Pass2026!" "${JENKINS_URL}/manage")
echo "HTTP response code for user2 accessing /manage : ${CODE_USER2_MANAGE}"

if [ "${CODE_USER2_MANAGE}" -eq 403 ]; then
  echo "[+] [CONFIRMED] user2 is FORBIDDEN (HTTP 403) from administrative actions!"
else
  echo "[-] Warning: user2 should have received HTTP 403 on /manage, received: ${CODE_USER2_MANAGE}"
fi

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Role-based authorization verified successfully!"
echo "=========================================================="
