#!/usr/bin/env bash
# ==============================================================================
# Script: 01-install-containerd.sh
# Purpose: Disable swap, configure kernel networking modules & sysctl parameters,
#          install and configure containerd with SystemdCgroup=true.
# Target: Run on ALL nodes (Control Plane and Worker Nodes)
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Step 1.1: Disabling Swap"
echo "=========================================================="
sudo swapoff -a
sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab

echo ">>> Verifying swap is disabled:"
free -h

echo "=========================================================="
echo ">>> Step 1.2: Loading Kernel Modules (overlay & br_netfilter)"
echo "=========================================================="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "=========================================================="
echo ">>> Step 1.3: Configuring Sysctl Parameters for Kubernetes"
echo "=========================================================="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "=========================================================="
echo ">>> Step 1.4: Installing Containerd Container Runtime"
echo "=========================================================="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Install containerd from official Docker apt repository or Ubuntu repositories
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y containerd.io

echo "=========================================================="
echo ">>> Step 1.5: Configuring Containerd (SystemdCgroup = true)"
echo "=========================================================="
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Set SystemdCgroup = true for runc
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd

echo ">>> Verifying containerd status:"
sudo systemctl status containerd --no-pager --lines=5

echo "=========================================================="
echo ">>> [SUCCESS] Containerd installation and configuration complete!"
echo "=========================================================="
