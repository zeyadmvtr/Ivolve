# Lab 10: Node Isolation Using Taints and Labels in Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Concepts](https://img.shields.io/badge/Scheduling-Taints_%26_Tolerations-4CAF50.svg)](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
[![Placement](https://img.shields.io/badge/Affinity-NodeSelector_%26_Labels-blue.svg)](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

This lab demonstrates how to achieve **dedicated node isolation** and **targeted workload scheduling** in a Kubernetes cluster using **Taints**, **Tolerations**, and **Node Labels**.

---

## 📋 Lab Objectives

- [x] **Apply a Taint** to a worker node with key `workload`, value `ivolveApp`, and effect `NoSchedule` to prevent pods from being scheduled on the node unless they possess a matching toleration.
- [x] **Label the same worker node** with `project=ivolve` to uniquely identify and target it for dedicated pod placement.
- [x] **Verify that the taint and label have been applied correctly** using:
  - `kubectl describe node <worker-node>`
  - `kubectl get nodes --show-labels`
- [x] **Validate scheduling behavior**:
  - Verify that untolerated pods are repelled from the tainted node.
  - Verify that tolerated pods can be scheduled onto the tainted node.
  - Verify that dedicated workloads combining `tolerations` + `nodeSelector` achieve mutual exclusive isolation on the targeted node.

---

## 🧠 Core Concepts: Taints, Tolerations, and Labels

```
                 +-----------------------------------------------------------+
                 |                     POD SCHEDULING                        |
                 +-----------------------------------------------------------+
                                               |
                                               v
        +-----------------------------------------------------------------------------+
        |                          KUBERNETES SCHEDULER                               |
        +-----------------------------------------------------------------------------+
               |                                                     |
  Does Pod have matching                                    Does Pod specify
  toleration for taint?                                     nodeSelector matching label?
               |                                                     |
       +-------+-------+                                     +-------+-------+
       |               |                                     |               |
      YES              NO                                   YES              NO
       |               |                                     |               |
       v               v                                     v               v
 [ Can Schedule ]  [ REPELLED ]                        [ Pinned to ]   [ Can Go to ]
 on Tainted Node   (Scheduling Rejected)               Target Node     Any Free Node
```

### 1. Taints & Tolerations (Repulsion)
- **Taints** are applied to **Nodes** to *repel* a set of pods.
- **Tolerations** are applied to **Pods** to allow (but not require) those pods to schedule onto nodes with matching taints.
- **Taint Effects**:
  - `NoSchedule`: Strong rule. If a pod does not have a matching toleration, Kubernetes will not schedule it onto this node. Existing running pods are not affected.
  - `PreferNoSchedule`: Soft rule. The scheduler avoids placing untolerated pods on the node if alternatives exist.
  - `NoExecute`: Eviction rule. Any existing pods on the node without the matching toleration will be evicted immediately (or after `tolerationSeconds`).

### 2. Labels & NodeSelectors (Attraction)
- **Labels** are key/value metadata attached to **Nodes**.
- **NodeSelector** is defined in the Pod spec to actively attract and pin the pod to nodes carrying matching labels.

### 3. The Power of Combining Both (Mutual Node Dedication)
| Technique | Repels Other Workloads? | Pins Targeted Workload? | Result |
| :--- | :---: | :---: | :--- |
| **Taint Only** | ✅ Yes | ❌ No (can land on other nodes) | Worker is protected, but target app might land elsewhere. |
| **Label Only** | ❌ No | ✅ Yes | Target app lands on node, but other apps can crowd it out. |
| **Taint + Label** | ✅ **Yes** | ✅ **Yes** | **100% Dedicated Worker Node Isolation** (Production Gold Standard). |

---

## 🗂️ Directory Structure

```
Lab-10-Kubernetes-Taints-and-Labels/
├── manifests/
│   ├── 01-untainted-default-pod.yaml        # Standard pod without toleration (repelled)
│   ├── 02-tolerated-pod.yaml                # Pod with toleration for workload=ivolveApp:NoSchedule
│   ├── 03-targeted-ivolveapp-deployment.yaml # Dedicated app (toleration + nodeSelector project=ivolve)
│   └── 04-node-affinity-ivolveapp.yaml      # Advanced placement using nodeAffinity
├── scripts/
│   ├── 01-apply-taint-and-label.sh          # Applies taint & label and executes verification
│   ├── 02-test-isolation.sh                 # Deploys test pods and inspects scheduler decisions
│   └── 03-cleanup.sh                        # Cleans up test pods and removes taints & labels
└── README.md                                # Detailed documentation and command walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Identify Target Worker Node

List the available nodes in the cluster:

```bash
kubectl get nodes
```

**Output:**
```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane   18m   v1.31.0
k8s-worker1   Ready    <none>          15m   v1.31.0
k8s-worker2   Ready    <none>          15m   v1.31.0
```

We will isolate **`k8s-worker1`**.

---

### Step 2: Apply Taint to Worker Node

Apply the taint with key `workload`, value `ivolveApp`, and effect `NoSchedule`:

```bash
kubectl taint nodes k8s-worker1 workload=ivolveApp:NoSchedule
```

**Output:**
```
node/k8s-worker1 tainted
```

---

### Step 3: Apply Label to Worker Node

Label the same worker node with `project=ivolve`:

```bash
kubectl label nodes k8s-worker1 project=ivolve
```

**Output:**
```
node/k8s-worker1 labeled
```

---

### Step 4: Verify Taint and Label via `kubectl describe node`

Verify the applied taint and labels on `k8s-worker1`:

```bash
kubectl describe node k8s-worker1 | grep -E "Name:|Labels:|Taints:" -A 4
```

**Output:**
```
Name:               k8s-worker1
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=k8s-worker1
                    kubernetes.io/os=linux
                    project=ivolve
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: unix:///run/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
Taints:             workload=ivolveApp:NoSchedule
Logging:            ...
```

---

### Step 5: Verify Labels via `kubectl get nodes --show-labels`

Query node labels across the entire cluster:

```bash
kubectl get nodes --show-labels
```

**Output:**
```
NAME          STATUS   ROLES           AGE   VERSION   LABELS
k8s-master    Ready    control-plane   20m   v1.31.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-master,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=
k8s-worker1   Ready    <none>          17m   v1.31.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-worker1,kubernetes.io/os=linux,project=ivolve
k8s-worker2   Ready    <none>          17m   v1.31.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-worker2,kubernetes.io/os=linux
```

Notice that `project=ivolve` is present exclusively on `k8s-worker1`.

---

## 🧪 Validating Node Isolation in Action

To prove that the taint and label effectively isolate the node, we run the automated test suite or apply manifests manually:

```bash
bash scripts/02-test-isolation.sh
```

### Scenario A: Untolerated Pod is Repelled

Manifest [`manifests/01-untainted-default-pod.yaml`](manifests/01-untainted-default-pod.yaml) does not configure any tolerations:

```bash
kubectl apply -f manifests/01-untainted-default-pod.yaml
```

The Kubernetes scheduler evaluates `k8s-worker1`, detects the untolerated taint `workload=ivolveApp:NoSchedule`, and places the pod on `k8s-worker2`:

```bash
kubectl get pod default-untainted-pod -o wide
```
**Output:**
```
NAME                    READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
default-untainted-pod   1/1     Running   0          12s   192.168.2.35   k8s-worker2   <none>           <none>
```

> **Note:** If no untainted nodes were available, the pod would remain in `Pending` with the event:
> `0/2 nodes available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 1 node(s) had untolerated taint {workload: ivolveApp}.`

---

### Scenario B: Tolerated Pod is Allowed

Manifest [`manifests/02-tolerated-pod.yaml`](manifests/02-tolerated-pod.yaml) includes the matching toleration:

```yaml
tolerations:
- key: "workload"
  operator: "Equal"
  value: "ivolveApp"
  effect: "NoSchedule"
```

```bash
kubectl apply -f manifests/02-tolerated-pod.yaml
kubectl get pod tolerated-ivolve-pod -o wide
```
**Output:**
```
NAME                   READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
tolerated-ivolve-pod   1/1     Running   0          8s    192.168.1.42   k8s-worker1   <none>           <none>
```

The pod is successfully scheduled on `k8s-worker1`!

---

### Scenario C: Dedicated Production Application (Toleration + NodeSelector)

Manifest [`manifests/03-targeted-ivolveapp-deployment.yaml`](manifests/03-targeted-ivolveapp-deployment.yaml) achieves complete node dedication:

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "ivolveApp"
        effect: "NoSchedule"
      nodeSelector:
        project: "ivolve"
```

```bash
kubectl apply -f manifests/03-targeted-ivolveapp-deployment.yaml
kubectl get pods -l app=ivolve-app -o wide
```

**Output:**
```
NAME                                    READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
ivolve-dedicated-app-6c9b489957-4wrlg   1/1     Running   0          15s   192.168.1.43   k8s-worker1   <none>           <none>
ivolve-dedicated-app-6c9b489957-8vfd9   1/1     Running   0          15s   192.168.1.44   k8s-worker1   <none>           <none>
```

Both replicas are placed exclusively on `k8s-worker1`.

---

## 🧹 Cleanup & Rollback

To remove test workloads, taints, and labels:

```bash
bash scripts/03-cleanup.sh
```

Or perform manual removal:

1. **Remove the Taint** (append a minus sign `-` to the taint key and effect):
   ```bash
   kubectl taint nodes k8s-worker1 workload=ivolveApp:NoSchedule-
   ```
   **Output:**
   ```
   node/k8s-worker1 untainted
   ```

2. **Remove the Label** (append a minus sign `-` to the label key):
   ```bash
   kubectl label nodes k8s-worker1 project-
   ```
   **Output:**
   ```
   node/k8s-worker1 unlabeled
   ```

3. **Delete Test Pods**:
   ```bash
   kubectl delete -f manifests/ --ignore-not-found=true
   ```

---

## 🏆 Production Use Cases for Taints & Labels

1. **Dedicated GPU / High-Compute Hardware**:
   - Prevent general lightweight microservices from wasting expensive GPU memory by tainting nodes with `sku=gpu:NoSchedule`.
   - Target AI/ML training workloads with `nodeSelector: gpu=nvidia-h100` and matching toleration.
2. **Multi-Tenant Team Isolation**:
   - Dedicate specific worker nodes to compliance-sensitive financial or medical data processing teams.
3. **Spot / Preemptible Node Handling**:
   - Taint spot instances with `lifecycle=spot:PreferNoSchedule` and tolerate only fault-tolerant background worker pods.
