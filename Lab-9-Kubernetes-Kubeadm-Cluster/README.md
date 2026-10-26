# Lab 9: Deploy Kubernetes Cluster Using Kubeadm

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Containerd](https://img.shields.io/badge/Containerd-v1.7+-575757.svg?logo=containerd&logoColor=white)](https://containerd.io/)
[![Calico](https://img.shields.io/badge/Calico_CNI-v3.28-FFA500.svg)](https://www.tigera.io/project-calico/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-E95420.svg?logo=ubuntu&logoColor=white)](https://ubuntu.com/)

This lab covers the end-to-end deployment and configuration of a production-ready, multi-node Kubernetes cluster from scratch using **Kubeadm**, **Containerd** (configured with systemd cgroup drivers), and the **Calico CNI** plugin for high-performance pod networking and network policy enforcement.

---

## 📋 Lab Objectives

- [x] **Install and configure Containerd** as the container runtime on all nodes (disabling swap, enabling `overlay` & `br_netfilter` kernel modules, configuring sysctl bridging flags, and enabling `SystemdCgroup = true`).
- [x] **Install kubeadm, kubelet, and kubectl** on both control plane and worker nodes from the official Kubernetes package repository (`pkgs.k8s.io`).
- [x] **Configure kubectl** on the control plane node to establish secure communication with the Kubernetes cluster via TLS certificates and kubeconfig.
- [x] **Install the Calico CNI plugin** to enable reliable pod networking and cross-node communication using a dedicated Pod CIDR (`192.168.0.0/16`).
- [x] **Initialize the control plane node** using `kubeadm init` with container runtime sockets and network CIDR configurations.
- [x] **Join the worker nodes** to the cluster securely using `kubeadm join` tokens and discovery SHA-256 certificate hashes.
- [x] **Verify cluster health and readiness**: Ensure all nodes transition to the `Ready` status and core control plane pods (`kube-apiserver`, `etcd`, `coredns`, `kube-proxy`, `calico-node`) are fully operational.

---

## 📐 Cluster Architecture Topology

```
+-------------------------------------------------------------------------------------------------+
|                                     KUBERNETES CLUSTER                                          |
|                                                                                                 |
|   +----------------------------------------------------+                                        |
|   |            Control Plane (k8s-master)              |                                        |
|   |                 192.168.56.10                      |                                        |
|   |  +----------------------------------------------+  |                                        |
|   |  | kube-apiserver (:6443)  |  etcd (:2379-2380) |  |                                        |
|   |  | kube-scheduler          |  kube-controller   |  |                                        |
|   |  | kube-proxy              |  coredns           |  |                                        |
|   |  | containerd runtime      |  kubelet.service   |  |                                        |
|   |  | Calico CNI Operator     |  admin.conf config |  |                                        |
|   |  +----------------------------------------------+  |                                        |
|   +----------------------------------------------------+                                        |
|                            |               |                                                    |
|                 VXLAN / BGP Calico Overlay | (Pod CIDR: 192.168.0.0/16)                         |
|                            v               v                                                    |
|   +---------------------------------+     +---------------------------------+                   |
|   |     Worker Node 1 (worker1)     |     |     Worker Node 2 (worker2)     |                   |
|   |          192.168.56.11          |     |          192.168.56.12          |                   |
|   |  +---------------------------+  |     |  +---------------------------+  |                   |
|   |  | kubelet.service           |  |     |  | kubelet.service           |  |                   |
|   |  | kube-proxy                |  |     |  | kube-proxy                |  |                   |
|   |  | containerd runtime        |  |     |  | containerd runtime        |  |                   |
|   |  | calico-node daemonset     |  |     |  | calico-node daemonset     |  |                   |
|   |  | Workload Pods             |  |     |  | Workload Pods             |  |                   |
|   |  +---------------------------+  |     |  +---------------------------+  |                   |
|   +---------------------------------+     +---------------------------------+                   |
+-------------------------------------------------------------------------------------------------+
```

---

## 🗂️ Directory Structure

```
Lab-9-Kubernetes-Kubeadm-Cluster/
├── manifests/
│   ├── calico-custom-resources.yaml  # Tigera Calico CNI IP pool configuration (192.168.0.0/16)
│   ├── kubeadm-config.yaml           # Declarative cluster init configuration
│   └── smoke-test.yaml               # Cluster verification deployment & service
├── scripts/
│   ├── 01-install-containerd.sh      # Swap disable, sysctl, kernel modules & containerd setup
│   ├── 02-install-kubeadm.sh         # Kubelet, kubeadm, and kubectl installation & version hold
│   ├── 03-init-control-plane.sh      # Control plane initialization & kubeconfig setup
│   ├── 04-install-calico.sh          # Calico Tigera Operator & CNI deployment
│   ├── 05-join-worker.sh             # Worker node join execution script
│   └── 06-verify-cluster.sh          # End-to-end verification and health inspection
├── Vagrantfile                       # Automated local 3-node VirtualBox environment
└── README.md                         # Complete documentation and execution guide
```

---

## 🚀 Step-by-Step Implementation Guide

### Prerequisites Matrix

Ensure network connectivity and open required ports across nodes:
- **Control Plane**: Inbound TCP `6443` (Kubernetes API), `2379-2380` (etcd), `10250` (Kubelet API), `10259` (Kube-scheduler), `10257` (Kube-controller-manager).
- **Worker Nodes**: Inbound TCP `10250` (Kubelet API), `10256` (kube-proxy), `30000-32767` (NodePort services).
- **Calico CNI**: Inbound/Outbound TCP `179` (BGP), UDP `4789` (VXLAN).

---

### Step 1: Install and Configure Containerd (All Nodes)

Execute `01-install-containerd.sh` on **both Control Plane and Worker nodes**:

```bash
sudo bash scripts/01-install-containerd.sh
```

**Actions Performed:**
1. **Disable Swap**: Kubernetes requires swap memory to be completely disabled to maintain deterministic resource allocation:
   ```bash
   sudo swapoff -a
   sudo sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab
   ```
2. **Load Kernel Modules**:
   ```bash
   cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
   overlay
   br_netfilter
   EOF
   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```
3. **Configure Sysctl Network Bridging**:
   ```bash
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   EOF
   sudo sysctl --system
   ```
4. **Install and Configure Containerd**:
   Generate default configuration and enforce systemd cgroups:
   ```bash
   sudo mkdir -p /etc/containerd
   containerd config default | sudo tee /etc/containerd/config.toml
   sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
   sudo systemctl restart containerd
   sudo systemctl enable containerd
   ```

**Output:**
```
>>> Step 1.1: Disabling Swap
>>> Step 1.2: Loading Kernel Modules (overlay & br_netfilter)
>>> Step 1.3: Configuring Sysctl Parameters for Kubernetes
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
>>> Step 1.4: Installing Containerd Container Runtime
>>> Step 1.5: Configuring Containerd (SystemdCgroup = true)
● containerd.service - containerd container runtime
     Loaded: loaded (/lib/systemd/system/containerd.service; enabled; vendor preset: enabled)
     Active: active (running)
>>> [SUCCESS] Containerd installation and configuration complete!
```

---

### Step 2: Install Kubeadm, Kubelet, and Kubectl (All Nodes)

Execute `02-install-kubeadm.sh` on **all nodes**:

```bash
sudo bash scripts/02-install-kubeadm.sh
```

**Actions Performed:**
1. Add the modern official Kubernetes repository (`pkgs.k8s.io`):
   ```bash
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```
2. Install tools and pin package versions to prevent unintended upgrades:
   ```bash
   sudo apt-get update
   sudo apt-get install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   sudo systemctl enable --now kubelet
   ```

**Output:**
```
>>> Installing kubelet, kubeadm, and kubectl
kubelet set on hold.
kubeadm set on hold.
kubectl set on hold.
>>> Verifying installed versions:
v1.31.0
Kubernetes v1.31.0
>>> [SUCCESS] Kubeadm, Kubelet, and Kubectl installed successfully!
```

---

### Step 3: Initialize the Control Plane Node (Control Plane Only)

Run `03-init-control-plane.sh` on the **Control Plane node**:

```bash
sudo bash scripts/03-init-control-plane.sh
```

**Command executed internally:**
```bash
sudo kubeadm init \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock
```

**Output:**
```
[init] Using Kubernetes version: v1.31.0
[certs] Generating PKI certificates and keys...
[certs] Certificate authority and keys successfully generated
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to bootup the control plane as static Pods
[apiclient] All control plane components are healthy after 8.502812 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" Namespace
[addons] Applied Essential Addon: CoreDNS
[addons] Applied Essential Addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!
```

---

### Step 4: Configure kubectl Communication

As part of `03-init-control-plane.sh`, regular non-root user access is established:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify connection to the API server:
```bash
kubectl cluster-info
```

**Output:**
```
Kubernetes control plane is running at https://192.168.56.10:6443
CoreDNS is running at https://192.168.56.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

### Step 5: Install Calico CNI Plugin (Control Plane Only)

Deploy the Calico CNI plugin using Tigera Operator to establish overlay pod networking:

```bash
bash scripts/04-install-calico.sh
```

**Command:**
```bash
# Install Tigera Operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

# Apply custom resources matching our pod network CIDR (192.168.0.0/16)
kubectl apply -f manifests/calico-custom-resources.yaml
```

**Output:**
```
namespace/tigera-operator created
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
deployment.apps/tigera-operator created
installation.operator.tigera.io/default created
apiserver.operator.tigera.io/default created
>>> [SUCCESS] Calico CNI plugin installed successfully!
```

Within 30–60 seconds, the Control Plane node will transition from `NotReady` to `Ready`:
```bash
kubectl get nodes
```
```
NAME         STATUS   ROLES           AGE     VERSION
k8s-master   Ready    control-plane   2m40s   v1.31.0
```

---

### Step 6: Join Worker Nodes to the Cluster (Worker Nodes Only)

On each worker node, run the join command generated during control plane initialization:

```bash
sudo kubeadm join 192.168.56.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --cri-socket=unix:///run/containerd/containerd.sock
```

> **Tip:** If the join token has expired or is lost, regenerate it at any time on the control plane with:
> ```bash
> kubeadm token create --print-join-command
> ```

**Worker Console Output:**
```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet. This takes up to 4m0s

This node has joined the cluster:
* Certificate signing request was sent to apiserver and was approved.
* Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

---

### Step 7: Verify Cluster Health & Node Readiness

Run the automated verification script from the Control Plane node:

```bash
bash scripts/06-verify-cluster.sh
```

#### 1. Node Status (`kubectl get nodes -o wide`):
```
NAME          STATUS   ROLES           AGE     VERSION   INTERNAL-IP     OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k8s-master    Ready    control-plane   6m20s   v1.31.0   192.168.56.10   Ubuntu 22.04.4 LTS   5.15.0-105-generic containerd://1.7.20
k8s-worker1   Ready    <none>          3m15s   v1.31.0   192.168.56.11   Ubuntu 22.04.4 LTS   5.15.0-105-generic containerd://1.7.20
k8s-worker2   Ready    <none>          2m55s   v1.31.0   192.168.56.12   Ubuntu 22.04.4 LTS   5.15.0-105-generic containerd://1.7.20
```

#### 2. System Pods Status (`kubectl get pods -A`):
```
NAMESPACE          NAME                                       READY   STATUS    RESTARTS   AGE
calico-apiserver   calico-apiserver-5d9c79f879-p58q9          1/1     Running   0          3m
calico-system      calico-kube-controllers-68485cbf9c-6x29l   1/1     Running   0          4m
calico-system      calico-node-b8wpx                          1/1     Running   0          4m
calico-system      calico-node-lsk92                          1/1     Running   0          3m
calico-system      calico-node-x7n2b                          1/1     Running   0          3m
calico-system      calico-typha-5b87445495-2s79f              1/1     Running   0          4m
kube-system        coredns-6f6b679f8f-4gdt5                   1/1     Running   0          6m
kube-system        coredns-6f6b679f8f-zpxq8                   1/1     Running   0          6m
kube-system        etcd-k8s-master                            1/1     Running   0          6m
kube-system        kube-apiserver-k8s-master                  1/1     Running   0          6m
kube-system        kube-controller-manager-k8s-master         1/1     Running   0          6m
kube-system        kube-proxy-8xflk                           1/1     Running   0          6m
kube-system        kube-proxy-m4sjk                           1/1     Running   0          3m
kube-system        kube-proxy-wn9sd                           1/1     Running   0          3m
kube-system        kube-scheduler-k8s-master                  1/1     Running   0          6m
tigera-operator    tigera-operator-588bc77665-mcfwt           1/1     Running   0          5m
```

#### 3. Smoke Test Pod Scheduling & Network Connectivity:
```
NAME                                 READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
ivolve-smoke-test-7bb5dfbc9d-8j2wq   1/1     Running   0          25s   192.168.1.15   k8s-worker1   <none>           <none>
ivolve-smoke-test-7bb5dfbc9d-fll9d   1/1     Running   0          25s   192.168.2.22   k8s-worker2   <none>           <none>
```

---

## 🛠️ Common Troubleshooting & FAQ

| Problem | Root Cause | Solution |
| :--- | :--- | :--- |
| `[ERROR Swap]: running with swap on is not supported` | Host swap is enabled | Run `sudo swapoff -a` and comment out swap entries in `/etc/fstab`. |
| `failed to run Kubelet: misconfigured cgroup driver` | Containerd and Kubelet cgroup mismatch | Ensure `SystemdCgroup = true` is set in `/etc/containerd/config.toml` and restart containerd. |
| Nodes stuck in `NotReady` status | CNI network plugin not installed or misconfigured | Deploy Calico CNI (`04-install-calico.sh`) and verify `calico-node` pods are running. |
| `kubeadm join` fails with connection timeout | Firewall blocking API server port `6443` | Allow inbound traffic on TCP `6443` on the control plane node. |
| Join token expired (`token was not found`) | Tokens expire after 24 hours by default | Generate a new token with `kubeadm token create --print-join-command`. |

---

## 🏁 Summary

You now have a fully operational multi-node Kubernetes cluster deployed via **kubeadm**, powered by **containerd** and interconnected with **Calico CNI**! You can now proceed to [Lab 10: Node Isolation Using Taints and Labels](../Lab-10-Kubernetes-Taints-and-Labels/README.md).
