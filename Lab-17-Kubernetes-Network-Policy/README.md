# Lab 17: Control Pod-to-Pod Traffic via Network Policy

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Security](https://img.shields.io/badge/Security-NetworkPolicy-critical.svg)](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
[![Calico](https://img.shields.io/badge/CNI-Calico-orange.svg)](https://www.tigera.io/project-calico/)

This lab demonstrates how to enforce zero-trust pod-to-pod network segmentation in Kubernetes using a **NetworkPolicy** (`ivolveNP`), restricting database ingress traffic strictly to authorized application pods on TCP port `3306`.

---

## 🎯 Lab Objectives

- [x] **Define a Network Policy** named `ivolveNP` in the `ivolve` namespace.
- [x] **Target Pod Selector**:
  - Targets the MySQL database pod (`app: ivolve-db`).
- [x] **Policy Types**:
  - Enforce **Only Ingress** traffic filtering.
- [x] **Ingress Rules**:
  - **Source Whitelist**: Allows traffic **only** from the application pods (`app: ivolve-app`).
  - **Port Restriction**: Restricts communication strictly to TCP port **3306** (MySQL default port).
- [x] **Validate Traffic Isolation**:
  - Confirm positive connectivity from authorized application pods (`app: ivolve-app`).
  - Confirm that connections from unauthorized or unlabelled pods are blocked and timed out by the CNI packet filter.

---

## 💡 Architecture & Security Model

By default, Kubernetes implements a flat, non-isolated network where all pods can communicate with any other pod across any namespace. Applying a `NetworkPolicy` transitions the targeted pods into **Isolated Mode**:
- Any ingress traffic not explicitly permitted by a rule is **dropped by default**.
- The CNI plugin (e.g., **Calico** deployed in Lab 9) translates the policy into kernel-level packet filtering rules via **iptables** or **eBPF**.

```
+---------------------------------------------------------------------------------------------------+
|                                  KUBERNETES 'ivolve' NAMESPACE                                    |
|                                                                                                   |
|    +-----------------------------+                                                                |
|    | Pod: ivolveApp              |                                                                |
|    | Label: app=ivolve-app       | ---- TCP 3306 ----+                                            |
|    +-----------------------------+                   |                                            |
|              (AUTHORIZED)                            v                                            |
|                                            +-------------------+                                  |
|                                            | NetworkPolicy:    |                                  |
|                                            |     ivolveNP      | ---> [ ALLOWED ]                 |
|                                            +-------------------+          |                       |
|    +-----------------------------+                   ^                    v                       |
|    | Pod: rogue / other pod      |                   |           +--------------------+           |
|    | Label: app=unauthorized     | ---- TCP 3306 ----+           | Pod: ivolveDB-0    |           |
|    +-----------------------------+                   |           | Label:             |           |
|             (UNAUTHORIZED)                           |           |   app=ivolve-db    |           |
|                                                      |           |                    |           |
|    +-----------------------------+                   |           | Port: 3306 (MySQL) |           |
|    | Pod: any pod                |                   |           +--------------------+           |
|    | Port: non-3306 (e.g. 8080)  | ---- TCP 8080 ----+                                            |
|    +-----------------------------+                                                                |
|          (INVALID PORT)                    [ DROPPED / TIMEOUT ]                                  |
+---------------------------------------------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-17-Kubernetes-Network-Policy/
├── manifests/
│   ├── 01-network-policy.yaml            # NetworkPolicy 'ivolveNP' (targets mysql, allows app on 3306)
│   ├── 02-authorized-client-pod.yaml     # Authorized tester pod (app=ivolve-app)
│   ├── 03-unauthorized-client-pod.yaml   # Unauthorized tester pod (app=unauthorized-client)
│   └── 04-default-deny-ingress.yaml      # Optional zero-trust default-deny manifest
├── scripts/
│   ├── 01-apply-network-policy.sh        # Applies and describes ivolveNP
│   ├── 02-test-traffic-isolation.sh      # Executes positive and negative connection tests
│   └── 03-cleanup.sh                     # Removes test pods
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Define and Apply NetworkPolicy `ivolveNP`

Apply the policy manifest:

```bash
kubectl apply -f manifests/01-network-policy.yaml
```

**Manifest (`manifests/01-network-policy.yaml`):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ivolveNP
  namespace: ivolve
  labels:
    app.kubernetes.io/name: ivolve-network-policy
    app.kubernetes.io/part-of: ivolve-platform
spec:
  podSelector:
    matchLabels:
      app: ivolve-db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: ivolve-app
      ports:
        - protocol: TCP
          port: 3306
```

Verify that the policy is recognized by the cluster:

```bash
kubectl get networkpolicy ivolveNP -n ivolve -o wide
```

**Output:**
```
NAME       POD-SELECTOR    AGE
ivolveNP   app=ivolve-db   15s
```

Inspect the parsed policy rules:

```bash
kubectl describe networkpolicy ivolveNP -n ivolve
```

**Output:**
```
Name:         ivolveNP
Namespace:    ivolve
Created on:   Mon, 02 Nov 2026 18:35:10 +0000
Labels:       app.kubernetes.io/name=ivolve-network-policy
              app.kubernetes.io/part-of=ivolve-platform
Annotations:  <none>
Spec:
  PodSelector:     app=ivolve-db
  Allowing ingress traffic:
    To Port: 3306/TCP
    From:
      PodSelector: app=ivolve-app
  Not affecting egress traffic
  Policy Types: Ingress
```

---

### Step 2: Validate Positive Connection from Authorized Pod

Deploy the authorized client pod labeled with `app: ivolve-app`:

```bash
kubectl apply -f manifests/02-authorized-client-pod.yaml
kubectl wait --for=condition=Ready pod/authorized-app-client -n ivolve --timeout=60s
kubectl logs -n ivolve authorized-app-client
```

**Output:**
```
Testing TCP connectivity from AUTHORIZED pod (app: ivolve-app) to ivolveDBSvc:3306...
ivolveDBSvc (192.168.1.42:3306) open
[SUCCESS] Connection to MySQL port 3306 allowed!
```

The TCP handshake succeeds immediately because the source pod carries the whitelisted label `app: ivolve-app`.

---

### Step 3: Validate Negative Connection from Unauthorized Pod

Deploy a pod lacking the whitelisted label (`app: unauthorized-client`):

```bash
kubectl apply -f manifests/03-unauthorized-client-pod.yaml
kubectl wait --for=condition=Ready pod/unauthorized-rogue-client -n ivolve --timeout=60s
kubectl logs -n ivolve unauthorized-rogue-client
```

**Output:**
```
Testing TCP connectivity from UNAUTHORIZED pod (app: unauthorized-client) to ivolveDBSvc:3306...
nc: ivolveDBSvc (192.168.1.42:3306): Operation timed out
[BLOCKED] Connection to MySQL port 3306 was successfully dropped by NetworkPolicy!
```

The SYN packet is silently dropped at the kernel level by Calico CNI rules. The client times out without receiving a response!

---

## ⚡ Automated Execution

```bash
# 1. Apply NetworkPolicy
bash scripts/01-apply-network-policy.sh

# 2. Test Traffic Isolation (Authorized vs Unauthorized)
bash scripts/02-test-traffic-isolation.sh

# 3. Clean up test pods
bash scripts/03-cleanup.sh
```

---

## 🛡️ Production Best Practices

1. **CNI Requirement**:
   Kubernetes NetworkPolicies require a CNI plugin that supports network policy enforcement (such as **Project Calico**, **Cilium**, or **Weave Net**). Standard `kubenet` or basic bridge plugins ignore NetworkPolicy manifests.
2. **Combine with Default-Deny**:
   In production, pair specific allow rules with a `default-deny-all-ingress` policy (`manifests/04-default-deny-ingress.yaml`) to ensure that newly added pods are secure by default until explicit permissions are granted.
3. **Egress Hardening**:
   Consider implementing `policyTypes: [Ingress, Egress]` to restrict pods from making unauthorized outbound calls or leaking data to external hosts.
