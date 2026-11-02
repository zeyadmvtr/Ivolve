# Lab 16: Pod Resource Management with CPU and Memory Requests and Limits

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Resources](https://img.shields.io/badge/Compute-Requests_%26_Limits-blue.svg)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
[![Metrics](https://img.shields.io/badge/Observability-Metrics_Server-orange.svg)](https://github.com/kubernetes-sigs/metrics-server)

This lab demonstrates how to manage compute resource allocation, scheduling guarantees, and runtime throttling in Kubernetes by configuring **CPU and Memory Requests and Limits** on the `ivolveApp` Deployment.

---

## 🎯 Lab Objectives

- [x] **Update the existing `ivolveApp` Deployment** in the `ivolve` namespace to specify precise resource constraints.
- [x] **Configure Resource Requests**:
  - `cpu`: `1` (1 vCPU / 1000m)
  - `memory`: `1Gi` (1 Gibibyte)
- [x] **Configure Resource Limits**:
  - `cpu`: `2` (2 vCPUs / 2000m)
  - `memory`: `2Gi` (2 Gibibytes)
- [x] **Verify Resource Constraints**:
  - Use `kubectl describe pod` to inspect and verify applied resource requests, limits, and Quality of Service (QoS) class.
- [x] **Monitor Real-Time Consumption**:
  - Use `kubectl top pod` to monitor live CPU and memory utilization across application pods under simulated traffic load.

---

## 💡 Architecture & Concepts

### 1. Requests vs. Limits: Scheduling vs. Enforcement

| Dimension | **Requests** (Guaranteed Baseline) | **Limits** (Hard Ceiling) |
| :--- | :--- | :--- |
| **Primary Consumer** | **Kubernetes Scheduler** (`kube-scheduler`) | **Linux Kernel** (`cgroups v2` / `containerd`) |
| **Purpose** | Guarantees minimum capacity required to schedule a Pod on a node. | Prevents noisy neighbors from monopolizing node resources. |
| **CPU Behavior** | Guaranteed compute cycles (CFS shares). | CPU throttling via CFS quota (`cpu.cfs_quota_us`). **Pods are never killed for CPU spikes.** |
| **Memory Behavior** | Reserved RAM on node. | Pod exceeds limit -> Linux kernel invokes OOMKiller (`OOMKilled`, exit code 137). |

```
                       NODE COMPUTE CAPACITY
+-------------------------------------------------------------------+
|  [=== 1 vCPU Request ===]                                         |
|  Guaranteed allocation for ivolveApp container                    |
+-------------------------------------------------------------------+
|  [=========================== 2 vCPU Limit =====================] |
|  Burst ceiling: throttled above 2000m (CFS quota enforcement)     |
+-------------------------------------------------------------------+

                        NODE MEMORY CAPACITY
+-------------------------------------------------------------------+
|  [=== 1 GiB Request ===]                                          |
|  Guaranteed RAM reservation for ivolveApp container               |
+-------------------------------------------------------------------+
|  [=========================== 2 GiB Limit =====================]  |
|  Hard ceiling: exceeding triggers OOMKiller (Exit 137)            |
+-------------------------------------------------------------------+
```

### 2. Quality of Service (QoS) Classes
Kubernetes assigns each Pod a **QoS Class** based on its container resource specifications:
1. **Guaranteed**: Every container specifies CPU and memory requests equal to limits. Highest priority during node eviction.
2. **Burstable**: Requests are less than limits (our configuration: 1 vCPU req / 2 vCPU lim; 1Gi req / 2Gi lim). Allows dynamic bursting while preserving a predictable floor.
3. **BestEffort**: Neither requests nor limits are specified. Lowest priority; first to be evicted when a node runs out of memory.

---

## 📁 Directory Structure

```
Lab-16-Kubernetes-Pod-Resource-Management/
├── manifests/
│   ├── 01-ivolveapp-deployment-resources.yaml # Updated Deployment with 1vCPU/1Gi req and 2vCPU/2Gi lim
│   ├── 02-patch-resources.yaml                # Strategic merge patch snippet
│   ├── 03-load-generator.yaml                 # HTTP load generator generating active traffic
│   └── 04-metrics-server.yaml                 # Metrics Server deployment manifest
├── scripts/
│   ├── 01-apply-resource-limits.sh            # Applies manifest and verifies rollout
│   ├── 02-verify-resources.sh                 # Inspects requests, limits & QoS class via kubectl describe
│   ├── 03-monitor-metrics.sh                  # Runs live metrics inspection with kubectl top pod
│   └── 04-cleanup.sh                          # Removes load generator
└── README.md                                  # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Update `ivolveApp` Deployment with Resources

Apply the updated deployment manifest or execute the strategic patch:

```bash
kubectl apply -f manifests/01-ivolveapp-deployment-resources.yaml
```

**Resource Block (`manifests/01-ivolveapp-deployment-resources.yaml` snippet):**
```yaml
containers:
  - name: ivolve-app
    image: zeyadmvtr/ivolve-app:latest
    resources:
      requests:
        cpu: "1"        # 1 vCPU (1000m)
        memory: "1Gi"   # 1 Gibibyte
      limits:
        cpu: "2"        # 2 vCPUs (2000m)
        memory: "2Gi"   # 2 Gibibytes
```

Wait for the rolling update to complete:
```bash
kubectl rollout status deployment/ivolveApp -n ivolve
```

**Output:**
```
Waiting for deployment "ivolveApp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "ivolveApp" rollout to finish: 1 of 2 updated replicas are available...
deployment "ivolveApp" successfully rolled out
```

---

### Step 2: Verify Applied Resources with `kubectl describe pod`

Inspect one of the newly scheduled application pods:

```bash
POD_NAME=$(kubectl get pods -n ivolve -l app=ivolve-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "${POD_NAME}" -n ivolve
```

**Output Snippet:**
```
Name:             ivolveApp-68df6d4f6c-8xk2w
Namespace:        ivolve
Priority:         0
Service Account:  default
Node:             k8s-worker1/192.168.1.20
Start Time:       Mon, 02 Nov 2026 18:30:15 +0000
Labels:           app=ivolve-app
                  pod-template-hash=68df6d4f6c
Status:           Running
IP:               192.168.1.58

Containers:
  ivolve-app:
    Container ID:   containerd://b27af89102c918a09f3e...
    Image:          zeyadmvtr/ivolve-app:latest
    Port:           3000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 02 Nov 2026 18:30:22 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  2Gi
    Requests:
      cpu:        1
      memory:     1Gi
    Environment:
      DB_HOST:      <set to key 'DB_HOST' of config map 'ivolveCM'>
      DB_USER:      <set to key 'DB_USER' of config map 'ivolveCM'>
      DB_PASSWORD:  <set to key 'DB_PASSWORD' of secret 'ivolveSecret'>
      DB_NAME:      ivolve
      PORT:         3000

QoS Class:                   Burstable
Node-Selectors:              project=ivolve
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
                             workload=ivolveApp:NoSchedule
```

Notice:
- **Requests**: `cpu: 1`, `memory: 1Gi`
- **Limits**: `cpu: 2`, `memory: 2Gi`
- **QoS Class**: Automatically computed as **`Burstable`**.

---

### Step 3: Monitor Real-Time Metrics with `kubectl top pod`

Ensure `metrics-server` is deployed in the cluster:
```bash
kubectl apply -f manifests/04-metrics-server.yaml
```

Generate HTTP traffic to stimulate CPU and memory activity:
```bash
kubectl apply -f manifests/03-load-generator.yaml
```

Monitor live container and pod metrics:

```bash
kubectl top pod -n ivolve --containers=true
```

**Output:**
```
POD                          NAME         CPU(cores)   MEMORY(bytes)   
ivolveApp-68df6d4f6c-8xk2w   ivolve-app   142m         78Mi            
ivolveApp-68df6d4f6c-w9kqt   ivolve-app   129m         76Mi            
ivolveDB-0                   mysql        52m          385Mi           
```

Monitor overall pod metrics across the `ivolve` namespace:

```bash
kubectl top pod -n ivolve
```

**Output:**
```
NAME                         CPU(cores)   MEMORY(bytes)   
ivolveApp-68df6d4f6c-8xk2w   142m         78Mi            
ivolveApp-68df6d4f6c-w9kqt   129m         76Mi            
ivolveDB-0                   52m          385Mi           
```

---

## ⚡ Automated Execution

```bash
# 1. Update deployment with resource requests and limits
bash scripts/01-apply-resource-limits.sh

# 2. Verify requests, limits, and QoS class
bash scripts/02-verify-resources.sh

# 3. Monitor real-time resource utilization via kubectl top pod
bash scripts/03-monitor-metrics.sh

# 4. Cleanup load generator
bash scripts/04-cleanup.sh
```
