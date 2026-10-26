#!/usr/bin/env bash
# ==============================================================================
# Script: 02-install-kubeadm.sh
# Purpose: Install kubeadm, kubelet, and kubectl from official pkgs.k8s.io repository.
# Target: Run on ALL nodes (Control Plane and Worker Nodes)
# ==============================================================================

set -euo pipefail

K8S_VERSION="${K8S_VERSION:-v1.31}"

echo "=========================================================="
echo ">>> Step 2.1: Installing Prerequisites for Kubernetes Repository"
echo "=========================================================="
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

echo "=========================================================="
echo ">>> Step 2.2: Adding Kubernetes Package Repository (${K8S_VERSION})"
echo "=========================================================="
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "=========================================================="
echo ">>> Step 2.3: Installing kubelet, kubeadm, and kubectl"
echo "=========================================================="
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

echo "=========================================================="
echo ">>> Step 2.4: Pinning Kubernetes Package Versions"
echo "=========================================================="
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl enable --now kubelet

echo ">>> Verifying installed versions:"
kubeadm version -o short
kubelet --version
kubectl version --client -o yaml

echo "=========================================================="
echo ">>> [SUCCESS] Kubeadm, Kubelet, and Kubectl installed successfully!"
echo "=========================================================="
