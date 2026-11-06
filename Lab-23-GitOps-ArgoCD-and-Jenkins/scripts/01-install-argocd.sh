#!/usr/bin/env bash
# ==============================================================================
# Script: 01-install-argocd.sh
# Purpose: Install Argo CD in Kubernetes cluster and expose UI via NodePort 30443
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1: Creating 'argocd' Namespace"
echo "=========================================================="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=========================================================="
echo ">>> Step 2: Installing Argo CD Core Components"
echo "=========================================================="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "=========================================================="
echo ">>> Step 3: Exposing Argo CD Server via NodePort (Port 30443)"
echo "=========================================================="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30443}]}}'

echo ""
echo ">>> Waiting for Argo CD components to reach Running state..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=180s
kubectl rollout status deployment/argocd-applicationset-controller -n argocd --timeout=180s

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] Argo CD installed and running in 'argocd' namespace!"
echo "=========================================================="
kubectl get pods -n argocd
