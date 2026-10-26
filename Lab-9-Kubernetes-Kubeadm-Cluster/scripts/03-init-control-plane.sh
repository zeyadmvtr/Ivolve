#!/usr/bin/env bash
# ==============================================================================
# Script: 03-init-control-plane.sh
# Purpose: Initialize Kubernetes Control Plane node with kubeadm init,
#          configure kubectl for the current user, and generate worker join script.
# Target: Run on CONTROL PLANE node ONLY
# ==============================================================================

set -euo pipefail

POD_CIDR="${POD_CIDR:-192.168.0.0/16}"
CONTROL_PLANE_IP=$(hostname -I | awk '{print $1}')
OUTPUT_JOIN_FILE="${OUTPUT_JOIN_FILE:-/tmp/kubeadm-join.sh}"

echo "=========================================================="
echo ">>> Step 3.1: Pre-pulling Kubernetes Control Plane Images"
echo "=========================================================="
sudo kubeadm config images pull

echo "=========================================================="
echo ">>> Step 3.2: Initializing Control Plane Node"
echo ">>> Advertising Address: ${CONTROL_PLANE_IP}"
echo ">>> Pod Network CIDR:    ${POD_CIDR}"
echo "=========================================================="

sudo kubeadm init \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}" \
  --pod-network-cidr="${POD_CIDR}" \
  --cri-socket="unix:///run/containerd/containerd.sock"

echo "=========================================================="
echo ">>> Step 3.3: Configuring kubectl for Current User ($(whoami))"
echo "=========================================================="
mkdir -p "$HOME/.kube"
sudo cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo ">>> Verifying cluster reachability via kubectl:"
kubectl cluster-info

echo "=========================================================="
echo ">>> Step 3.4: Generating Worker Node Join Script"
echo "=========================================================="
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "#!/usr/bin/env bash" > "${OUTPUT_JOIN_FILE}"
echo "sudo ${JOIN_CMD}" >> "${OUTPUT_JOIN_FILE}"
chmod +x "${OUTPUT_JOIN_FILE}"

echo ">>> Worker join command saved to: ${OUTPUT_JOIN_FILE}"
echo ">>> To join worker nodes, execute:"
echo "----------------------------------------------------------"
echo "sudo ${JOIN_CMD}"
echo "----------------------------------------------------------"

echo "=========================================================="
echo ">>> [SUCCESS] Control Plane initialized and kubectl configured!"
echo "=========================================================="
