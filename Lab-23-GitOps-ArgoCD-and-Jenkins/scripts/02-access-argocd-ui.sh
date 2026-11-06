#!/usr/bin/env bash
# ==============================================================================
# Script: 02-access-argocd-ui.sh
# Purpose: Retrieve initial admin password and display UI login coordinates
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Retrieving Argo CD Initial Admin Password"
echo "=========================================================="

ADMIN_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo ""
echo "=========================================================="
echo ">>> Argo CD UI Login Credentials"
echo "=========================================================="
echo "Web URL   : https://${NODE_IP}:30443 (or https://localhost:30443 via port-forward)"
echo "Username  : admin"
echo "Password  : ${ADMIN_PASSWORD}"
echo "=========================================================="
echo ""
echo "To port-forward locally to port 8080 run:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
