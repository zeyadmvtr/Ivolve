# Lab 11: Namespace Management and Resource Quota Enforcement

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ResourceQuota](https://img.shields.io/badge/Governance-ResourceQuota-orange.svg)](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
[![Multi--Tenancy](https://img.shields.io/badge/Architecture-Multi--Tenancy-blue.svg)](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

This lab demonstrates how to implement **namespace isolation** and enforce **workload boundaries** in a Kubernetes cluster using **Namespaces** and **ResourceQuotas**.

---

## 🎯 Lab Objectives

- [x] **Create a Kubernetes namespace** named `ivolve` to isolate application resources and isolate multi-tenant workloads.
- [x] **Create a ResourceQuota** named `ivolveQuota` in the `ivolve` namespace to strictly limit the total number of pods to **3**.
- [x] **Verify ResourceQuota application**:
  - Inspect quota state and active usage using `kubectl describe resourcequota ivolveQuota -n ivolve`.
- [x] **Confirm quota enforcement**:
  - Demonstrate successful pod scheduling up to the limit (3 pods).
  - Confirm Kubernetes API and admission controllers reject extra pod creation when the 3-pod limit is reached (`forbidden: exceeded quota`).

---

## 💡 Architecture & Concepts

### 1. Kubernetes Namespaces
A **Namespace** provides a scope for Kubernetes object names and serves as a virtual cluster boundary within a physical Kubernetes cluster. Namespaces provide:
- **Logical separation**: Decoupling teams, environments (`dev`, `staging`, `prod`), or microservices.
- **Scope for policies**: Enabling targeted RBAC, NetworkPolicies, and ResourceQuotas.

### 2. ResourceQuota Admission Control
A **ResourceQuota** provides constraints that limit aggregate resource consumption per namespace. When a pod is submitted:
1. The **ResourceQuota Admission Controller** intercepts the request.
2. It checks whether adding the resource would exceed the configured `hard` limit.
3. If within limits, the pod is admitted and `used` is incremented.
4. If limit is exceeded, HTTP 403 Forbidden is returned with `exceeded quota: <quota-name>`.

```
                    +----------------------------------------------------+
                    |             KUBERNETES API REQUEST                 |
                    |             kubectl apply / create                 |
                    +----------------------------------------------------+
                                              |
                                              v
                    +----------------------------------------------------+
                    |        RESOURCEQUOTA ADMISSION CONTROLLER          |
                    +----------------------------------------------------+
                                              |
                     Current Pods in 'ivolve': count < 3 ?
                                              |
                          +-------------------+-------------------+
                          |                                       |
                         YES                                      NO
                          |                                       |
                          v                                       v
               +----------------------+               +-----------------------+
               |    ADMIT REQUEST     |               |   REJECT (403 HTTP)   |
               |  used count -> +1    |               | "exceeded quota:      |
               | Pod Scheduled to Node|               |  ivolveQuota"         |
               +----------------------+               +-----------------------+
```

---

## 📁 Directory Structure

```
Lab-11-Kubernetes-Namespace-and-ResourceQuota/
├── manifests/
│   ├── 01-namespace.yaml                 # Namespace manifest for 'ivolve'
│   ├── 02-resource-quota.yaml            # ResourceQuota 'ivolveQuota' limiting pods to 3
│   ├── 03-quota-test-deployment.yaml     # 3-replica deployment testing quota capacity
│   └── 04-exceed-quota-pod.yaml          # 4th pod attempting to breach quota
├── scripts/
│   ├── 01-setup-namespace-quota.sh       # Automated creation of namespace & quota
│   ├── 02-verify-quota.sh                # End-to-end quota validation & error inspection
│   └── 03-cleanup.sh                     # Workload teardown script
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Create the `ivolve` Namespace

Apply the namespace manifest:

```bash
kubectl apply -f manifests/01-namespace.yaml
```

**Manifest (`manifests/01-namespace.yaml`):**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ivolve
  labels:
    name: ivolve
    environment: dev
    managed-by: kubernetes
```

**Output:**
```
namespace/ivolve created
```

Verify the namespace:
```bash
kubectl get namespace ivolve --show-labels
```

**Output:**
```
NAME     STATUS   AGE   LABELS
ivolve   Active   10s   environment=dev,managed-by=kubernetes,name=ivolve
```

---

### Step 2: Apply the `ivolveQuota` ResourceQuota

Apply the quota to restrict total pods in `ivolve` to 3:

```bash
kubectl apply -f manifests/02-resource-quota.yaml
```

**Manifest (`manifests/02-resource-quota.yaml`):**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ivolveQuota
  namespace: ivolve
spec:
  hard:
    pods: "3"
```

**Output:**
```
resourcequota/ivolveQuota created
```

---

### Step 3: Inspect ResourceQuota State

Check the current quota limits and usage:

```bash
kubectl describe resourcequota ivolveQuota -n ivolve
```

**Output:**
```
Name:       ivolveQuota
Namespace:  ivolve
Resource    Used  Hard
--------    ----  ----
pods        0     3
```

---

### Step 4: Deploy 3 Replicas (Filling the Quota)

Deploy the test deployment configured with 3 replicas:

```bash
kubectl apply -f manifests/03-quota-test-deployment.yaml
kubectl rollout status deployment/quota-test-workload -n ivolve
```

Verify that all 3 pods are running:

```bash
kubectl get pods -n ivolve
```

**Output:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
quota-test-workload-74bc84478f-6g2kd   1/1     Running   0          22s
quota-test-workload-74bc84478f-9xmpk   1/1     Running   0          22s
quota-test-workload-74bc84478f-z842h   1/1     Running   0          22s
```

Check the updated ResourceQuota:

```bash
kubectl describe resourcequota ivolveQuota -n ivolve
```

**Output:**
```
Name:       ivolveQuota
Namespace:  ivolve
Resource    Used  Hard
--------    ----  ----
pods        3     3
```

---

### Step 5: Verify Quota Enforcement (Attempting to Exceed Limits)

#### Test A: Standalone Pod Creation
Attempt to create a 4th pod using `manifests/04-exceed-quota-pod.yaml`:

```bash
kubectl apply -f manifests/04-exceed-quota-pod.yaml
```

**Expected Error Output:**
```
Error from server (Forbidden): error when creating "manifests/04-exceed-quota-pod.yaml": pods "extra-test-pod" is forbidden: exceeded quota: ivolveQuota, requested: pods=1, used: pods=3, limited: pods=3
```

Kubernetes directly rejects the creation request via the admission controller!

#### Test B: Deployment Scale Out
Attempt to scale the deployment from 3 to 4 replicas:

```bash
kubectl scale deployment quota-test-workload -n ivolve --replicas=4
```

Inspect the ReplicaSet events:

```bash
kubectl describe rs -l app=quota-test -n ivolve
```

**Output Snippet:**
```
Events:
  Type     Reason        Age                From                   Message
  ----     ------        ----               ----                   -------
  Warning  FailedCreate  12s (x4 over 30s)  replicaset-controller  Error creating: pods "quota-test-workload-74bc84478f-abcde" is forbidden: exceeded quota: ivolveQuota, requested: pods=1, used: pods=3, limited: pods=3
```

The ReplicaSet controller is actively blocked from creating any additional pod beyond the quota.

---

## ⚡ Automated Execution

Run the complete setup and validation via the automated scripts:

```bash
# 1. Setup namespace and quota
bash scripts/01-setup-namespace-quota.sh

# 2. Run verification suite
bash scripts/02-verify-quota.sh

# 3. Cleanup test workloads
bash scripts/03-cleanup.sh
```

---

## 🛡️ Production Best Practices

1. **Always Pair Quotas with LimitRanges**:
   When enforcing compute quotas (`requests.cpu`, `limits.memory`), a pod must specify resource requests to be admitted. Configure a `LimitRange` with default requests to prevent unintended rejections.
2. **Scope Selectors**:
   ResourceQuotas can filter pods by scope (e.g., `BestEffort`, `NotBestEffort`, `Terminating`) to control transient batch jobs independently from persistent daemons.
3. **Multi-Tenant Segregation**:
   Combine ResourceQuotas with Kubernetes RBAC to grant developers access only to their assigned namespace.
