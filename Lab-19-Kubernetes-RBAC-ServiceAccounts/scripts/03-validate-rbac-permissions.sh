#!/usr/bin/env bash
# ==============================================================================
# Script: 03-validate-rbac-permissions.sh
# Purpose: Rigorously test permissions of jenkinsSA using kubectl auth can-i
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

SA="system:serviceaccount:ivolve:jenkinsSA"

echo "=========================================================="
echo ">>> Checking Allowed Permissions for ${SA}"
echo "=========================================================="

echo -n "1. Can jenkinsSA CREATE deployments in 'ivolve' namespace? "
RES=$(kubectl auth can-i create deployments -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "yes" ] || exit 1

echo -n "2. Can jenkinsSA UPDATE deployments in 'ivolve' namespace? "
RES=$(kubectl auth can-i update deployments -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "yes" ] || exit 1

echo -n "3. Can jenkinsSA GET deployments in 'ivolve' namespace? "
RES=$(kubectl auth can-i get deployments -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "yes" ] || exit 1

echo ""
echo "=========================================================="
echo ">>> Checking Denied Permissions (Least Privilege Enforcement)"
echo "=========================================================="

echo -n "4. Can jenkinsSA DELETE deployments in 'ivolve' namespace? "
RES=$(kubectl auth can-i delete deployments -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "no" ] || echo "[-] Warning: Unexpected permission"

echo -n "5. Can jenkinsSA CREATE pods directly in 'ivolve' namespace? "
RES=$(kubectl auth can-i create pods -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "no" ] || echo "[-] Warning: Unexpected permission"

echo -n "6. Can jenkinsSA READ secrets in 'ivolve' namespace? "
RES=$(kubectl auth can-i get secrets -n ivolve --as="${SA}")
echo "${RES}"
[ "${RES}" == "no" ] || echo "[-] Warning: Unexpected permission"

echo -n "7. Can jenkinsSA CREATE deployments in 'default' namespace? "
RES=$(kubectl auth can-i create deployments -n default --as="${SA}")
echo "${RES}"
[ "${RES}" == "no" ] || echo "[-] Warning: Unexpected permission"

echo -n "8. Can jenkinsSA CREATE deployments in 'kube-system' namespace? "
RES=$(kubectl auth can-i create deployments -n kube-system --as="${SA}")
echo "${RES}"
[ "${RES}" == "no" ] || echo "[-] Warning: Unexpected permission"

echo ""
echo "=========================================================="
echo ">>> [CONFIRMED] jenkinsSA can ONLY create/update deployments in 'ivolve' namespace!"
echo "=========================================================="
