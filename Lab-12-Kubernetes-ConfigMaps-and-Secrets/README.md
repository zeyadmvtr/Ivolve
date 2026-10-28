# Lab 12: Managing Configuration and Sensitive Data with ConfigMaps and Secrets

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ConfigMap](https://img.shields.io/badge/Config-ConfigMap-blue.svg)](https://kubernetes.io/docs/concepts/configuration/configmap/)
[![Secret](https://img.shields.io/badge/Security-Secret_%28Base64%29-critical.svg)](https://kubernetes.io/docs/concepts/configuration/secret/)

This lab demonstrates how to decouple application configuration from container images in Kubernetes using **ConfigMaps** for non-sensitive data and **Secrets** with **Base64 encoding** for credentials.

---

## 🎯 Lab Objectives

- [x] **Create a ConfigMap named `ivolveCM`** in the `ivolve` namespace to store non-sensitive MySQL configuration variables:
  - `DB_HOST`: Hostname of the MySQL StatefulSet's headless Service (`ivolveDBSvc`).
  - `DB_USER`: Application database user authorized to connect to the database (`ivolveuser`).
- [x] **Create a Secret named `ivolveSecret`** in the `ivolve` namespace to store sensitive credentials:
  - `MYSQL_ROOT_PASSWORD`: Root administrator password for MySQL.
  - `DB_PASSWORD`: Password for the application database user specified by `DB_USER`.
- [x] **Use Base64 encoding** to encode the Secret data values when defining the Secret in a YAML manifest (`data:` field).
- [x] **Verify configuration delivery**:
  - Deploy a workload consuming both `ivolveCM` and `ivolveSecret` via environment variables.
  - Confirm accurate variable injection and decode values from the cluster.

---

## 💡 Architecture & Concepts

### Configuration Decoupling in Kubernetes
Hardcoding database hosts and passwords into Docker images violates the 12-Factor App methodology and introduces security vulnerabilities. Kubernetes solves this by abstracting configuration:

```
                      +----------------------------------------------------+
                      |               KUBERNETES ETCD STORE                |
                      +----------------------------------------------------+
                                    |                         |
                                    v                         v
               +---------------------------+     +---------------------------+
               |        ConfigMap          |     |          Secret           |
               |       'ivolveCM'          |     |       'ivolveSecret'      |
               +---------------------------+     +---------------------------+
               | DB_HOST: ivolveDBSvc      |     | MYSQL_ROOT_PASSWORD: (b64)|
               | DB_USER: ivolveuser       |     | DB_PASSWORD:         (b64)|
               +---------------------------+     +---------------------------+
                                    \                         /
                                     \                       /
                              Injected via 'valueFrom' / 'env'
                                       \                   /
                                        v                 v
                               +-----------------------------------+
                               |          APPLICATION POD          |
                               |    (ivolveDB / ivolve-consumer)   |
                               +-----------------------------------+
                               |  $DB_HOST = ivolveDBSvc           |
                               |  $DB_USER = ivolveuser            |
                               |  $MYSQL_ROOT_PASSWORD = ********  |
                               |  $DB_PASSWORD = ********          |
                               +-----------------------------------+
```

### Base64 Encoding vs Encryption
Kubernetes Secret manifests use Base64 encoding under the `data` field to allow storing arbitrary binary or special-character strings without YAML parsing corruption.
> ⚠️ **Security Note**: Base64 is an **encoding scheme**, not encryption. In production, protect secrets at rest using **KMS Envelope Encryption** and control access using strict **Kubernetes RBAC**.

---

## 📁 Directory Structure

```
Lab-12-Kubernetes-ConfigMaps-and-Secrets/
├── manifests/
│   ├── 01-configmap.yaml                 # ConfigMap 'ivolveCM' (DB_HOST, DB_USER)
│   ├── 02-secret.yaml                    # Base64-encoded Secret 'ivolveSecret'
│   └── 03-consumer-pod.yaml              # Pod testing environment injection
├── scripts/
│   ├── 01-create-config-and-secret.sh    # Encodes credentials & applies manifests
│   ├── 02-verify-injection.sh            # Validates environment inside container
│   └── 03-cleanup.sh                     # Removes test consumer pod
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Base64 Encode Secret Credentials

Encode the database passwords using Linux `base64`:

```bash
# Encode Root Password
echo -n "ivolveRootPass2026!" | base64
# Output: aXZvbHZlUm9vdFBhc3MyMDI2IQ==

# Encode Application User Password
echo -n "ivolveUserPass2026!" | base64
# Output: aXZvbHZlVXNlclBhc3MyMDI2IQ==
```

> **Important**: The `-n` flag in `echo -n` prevents appending a trailing newline character `\n` to the password string before encoding.

---

### Step 2: Create ConfigMap `ivolveCM`

Apply the ConfigMap containing non-sensitive configuration:

```bash
kubectl apply -f manifests/01-configmap.yaml
```

**Manifest (`manifests/01-configmap.yaml`):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ivolveCM
  namespace: ivolve
  labels:
    app.kubernetes.io/part-of: ivolve-platform
    app.kubernetes.io/component: database-config
data:
  DB_HOST: "ivolveDBSvc"
  DB_USER: "ivolveuser"
```

Verify the ConfigMap:
```bash
kubectl describe configmap ivolveCM -n ivolve
```

**Output:**
```
Name:         ivolveCM
Namespace:    ivolve
Labels:       app.kubernetes.io/component=database-config
              app.kubernetes.io/part-of=ivolve-platform
Annotations:  <none>

Data
====
DB_HOST:
----
ivolveDBSvc
DB_USER:
----
ivolveuser

BinaryData
====

Events:  <none>
```

---

### Step 3: Create Secret `ivolveSecret`

Apply the Secret containing Base64 encoded credentials:

```bash
kubectl apply -f manifests/02-secret.yaml
```

**Manifest (`manifests/02-secret.yaml`):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ivolveSecret
  namespace: ivolve
  labels:
    app.kubernetes.io/part-of: ivolve-platform
    app.kubernetes.io/component: database-credentials
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: aXZvbHZlUm9vdFBhc3MyMDI2IQ==
  DB_PASSWORD: aXZvbHZlVXNlclBhc3MyMDI2IQ==
```

Verify the Secret:
```bash
kubectl describe secret ivolveSecret -n ivolve
```

**Output:**
```
Name:         ivolveSecret
Namespace:    ivolve
Labels:       app.kubernetes.io/component=database-credentials
              app.kubernetes.io/part-of=ivolve-platform
Annotations:  <none>

Type:  Opaque

Data
====
DB_PASSWORD:          19 bytes
MYSQL_ROOT_PASSWORD:  19 bytes
```

---

### Step 4: Verify Environment Injection in Pods

Deploy the consumer test pod:

```bash
kubectl apply -f manifests/03-consumer-pod.yaml
kubectl wait --for=condition=Ready pod/ivolve-config-consumer -n ivolve --timeout=60s
```

**Pod Manifest (`manifests/03-consumer-pod.yaml` snippet):**
```yaml
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: ivolveCM
              key: DB_HOST
        - name: DB_USER
          valueFrom:
            configMapKeyRef:
              name: ivolveCM
              key: DB_USER
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ivolveSecret
              key: MYSQL_ROOT_PASSWORD
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ivolveSecret
              key: DB_PASSWORD
```

Inspect the injected environment variables inside the pod:

```bash
kubectl exec -n ivolve ivolve-config-consumer -- env | grep -E "DB_|MYSQL_"
```

**Output:**
```
DB_HOST=ivolveDBSvc
DB_USER=ivolveuser
MYSQL_ROOT_PASSWORD=ivolveRootPass2026!
DB_PASSWORD=ivolveUserPass2026!
```

---

### Step 5: Decode Secret via Kubectl API

Verify that Kubernetes accurately stores and presents decoded values:

```bash
kubectl get secret ivolveSecret -n ivolve -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
echo ""
```

**Output:**
```
ivolveUserPass2026!
```

---

## ⚡ Automated Execution

Run all steps using the bundled automation scripts:

```bash
# 1. Base64 encode and apply manifests
bash scripts/01-create-config-and-secret.sh

# 2. Deploy consumer pod & verify injection
bash scripts/02-verify-injection.sh

# 3. Clean up test pod (preserving configs for Lab 14)
bash scripts/03-cleanup.sh
```
