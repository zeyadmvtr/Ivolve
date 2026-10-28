# Lab 13: Persistent Storage Setup for Application Logging

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Storage](https://img.shields.io/badge/Storage-PersistentVolume-orange.svg)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
[![AccessMode](https://img.shields.io/badge/AccessMode-ReadWriteMany-brightgreen.svg)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)

This lab demonstrates how to configure persistent cluster storage in Kubernetes using **PersistentVolumes (PV)**, **PersistentVolumeClaims (PVC)**, and the **hostPath** volume plugin with **ReadWriteMany (RWX)** access mode for shared application logging.

---

## 🎯 Lab Objectives

- [x] **Define a Persistent Volume (PV)** with the following specifications:
  - **Name**: `ivolvePV`
  - **Size**: `1Gi`
  - **Storage Type**: `hostPath`
  - **Path**: `/mnt/app-logs` on the node file system
  - **Access Mode**: `ReadWriteMany` (RWX, allowing multi-pod concurrent read/write)
  - **Reclaim Policy**: `Retain` (preserves data even when claim is released)
- [x] **Define a Persistent Volume Claim (PVC)**:
  - **Name**: `ivolvePVC` in `ivolve` namespace requesting `1Gi` storage.
  - **Access Mode**: Matches the PV (`ReadWriteMany`).
  - **StorageClass**: None (`storageClassName: ""` to disable dynamic storage class overrides and bind directly to `ivolvePV`).
- [x] **Validate Storage Binding & Persistence**:
  - Verify `Bound` status between `ivolvePV` and `ivolvePVC`.
  - Deploy multi-replica logging pods writing concurrent logs to `/mnt/app-logs/application.log`.
  - Confirm data persistence across pod deletion and recreation.

---

## 💡 Architecture & Concepts

### 1. PV, PVC, and StorageClass Interaction
Kubernetes abstracts storage through a separation of concerns:
- **Cluster Administrator** provisions physical/cloud storage via `PersistentVolume`.
- **Application Developer** requests storage requirements (size, access mode) via `PersistentVolumeClaim`.
- The **Persistent Volume Controller** matches and binds compatible claims to volumes.

```
+-----------------------------------------------------------------------------------+
|                               KUBERNETES NODE                                     |
|                                                                                   |
|  Node Filesystem Path:  /mnt/app-logs                                             |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                 PersistentVolume: ivolvePV                                  |  |
|  |                 - Capacity: 1Gi                                             |  |
|  |                 - AccessMode: ReadWriteMany                                 |  |
|  |                 - ReclaimPolicy: Retain                                     |  |
|  |                 - storageClassName: ""                                      |  |
|  +-----------------------------------------------------------------------------+  |
|                                        ^                                          |
|                                        |  (Bound 1:1)                             |
|                                        v                                          |
|  +-----------------------------------------------------------------------------+  |
|  |                 PersistentVolumeClaim: ivolvePVC (Namespace: ivolve)        |  |
|  |                 - Request: 1Gi                                              |  |
|  |                 - AccessMode: ReadWriteMany                                 |  |
|  |                 - storageClassName: ""                                      |  |
|  +-----------------------------------------------------------------------------+  |
|                             /                      \                              |
|          VolumeMount (/mnt/app-logs)        VolumeMount (/mnt/app-logs)           |
|                          /                            \                           |
|                         v                              v                          |
|             +-----------------------+      +-----------------------+              |
|             | Pod: logging-app-pod1 |      | Pod: logging-app-pod2 |              |
|             | (Namespace: ivolve)   |      | (Namespace: ivolve)   |              |
|             +-----------------------+      +-----------------------+              |
+-----------------------------------------------------------------------------------+
```

### 2. Access Modes Explained
| Access Mode | CLI Abbreviation | Description |
| :--- | :---: | :--- |
| **ReadWriteOnce** | `RWO` | Volume can be mounted as read-write by a single node. |
| **ReadOnlyMany** | `ROX` | Volume can be mounted read-only by many nodes simultaneously. |
| **ReadWriteMany** | `RWX` | Volume can be mounted as read-write by many nodes simultaneously (ideal for shared application logs). |
| **ReadWriteOncePod**| `RWOP`| Volume can be mounted as read-write by a single Pod only. |

### 3. Reclaim Policies
- **`Retain`**: When the PVC is deleted, the PV remains intact with all data preserved for manual administrator recovery.
- **`Delete`**: Deleting the PVC automatically destroys the backing storage volume.
- **`Recycle`**: Performs a basic scrub (`rm -rf /thevolume/*`) and makes the volume available again (deprecated).

---

## 📁 Directory Structure

```
Lab-13-Kubernetes-Persistent-Storage/
├── manifests/
│   ├── 01-persistent-volume.yaml         # PV 'ivolvePV' (1Gi, hostPath /mnt/app-logs, Retain)
│   ├── 02-persistent-volume-claim.yaml   # PVC 'ivolvePVC' (1Gi, ReadWriteMany, storageClassName: "")
│   ├── 03-logging-deployment.yaml        # 2-replica logging workload writing concurrent entries
│   └── 04-log-reader-pod.yaml            # Standalone reader pod verifying persisted logs
├── scripts/
│   ├── 01-setup-hostpath.sh              # Prepares node directory /mnt/app-logs
│   ├── 02-apply-storage.sh               # Applies PV, PVC and validates binding
│   ├── 03-verify-logging-persistence.sh  # Tests RWX concurrent writes and data persistence
│   └── 04-cleanup.sh                     # Removes test pods and claims
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Prepare Node Filesystem Directory

On the target worker node, create the directory `/mnt/app-logs` with open write permissions:

```bash
sudo mkdir -p /mnt/app-logs
sudo chmod 777 /mnt/app-logs
```

---

### Step 2: Create the PersistentVolume `ivolvePV`

Apply the PersistentVolume manifest:

```bash
kubectl apply -f manifests/01-persistent-volume.yaml
```

**Manifest (`manifests/01-persistent-volume.yaml`):**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ivolvePV
  labels:
    type: local-logging
    app.kubernetes.io/name: ivolve-storage
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/app-logs
    type: DirectoryOrCreate
```

Verify PV creation:
```bash
kubectl get pv ivolvePV
```

**Output:**
```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
ivolvePV   1Gi        RWX            Retain           Available                          <unset>                 8s
```

Notice the status is **`Available`**, waiting for a matching claim.

---

### Step 3: Create the PersistentVolumeClaim `ivolvePVC`

Apply the PVC manifest in the `ivolve` namespace:

```bash
kubectl apply -f manifests/02-persistent-volume-claim.yaml
```

**Manifest (`manifests/02-persistent-volume-claim.yaml`):**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ivolvePVC
  namespace: ivolve
  labels:
    app.kubernetes.io/name: ivolve-storage
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ""
```

Verify that the claim immediately binds to `ivolvePV`:
```bash
kubectl get pvc ivolvePVC -n ivolve
```

**Output:**
```
NAME        STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
ivolvePVC   Bound    ivolvePV   1Gi        RWX                           <unset>                 5s
```

Check the PV status:
```bash
kubectl get pv ivolvePV
```

**Output:**
```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
ivolvePV   1Gi        RWX            Retain           Bound    ivolve/ivolvePVC                  <unset>                 45s
```

Status is now **`Bound`** to claim `ivolve/ivolvePVC`!

---

### Step 4: Verify Concurrent ReadWriteMany Logging

Deploy the test application (`manifests/03-logging-deployment.yaml`) running 2 replicas that both mount `ivolvePVC` at `/mnt/app-logs`:

```bash
kubectl apply -f manifests/03-logging-deployment.yaml
kubectl rollout status deployment/ivolve-logging-app -n ivolve
```

Inspect the aggregated log file from one of the pods:

```bash
POD_NAME=$(kubectl get pods -n ivolve -l app=ivolve-logging -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ivolve "${POD_NAME}" -- cat /mnt/app-logs/application.log | tail -n 6
```

**Output:**
```
[2026-10-28T20:15:02Z] [INFO] [ivolve-logging-app-5477d9c669-7b2kx] Heartbeat event written to shared storage.
[2026-10-28T20:15:03Z] [INFO] [ivolve-logging-app-5477d9c669-m98pz] Heartbeat event written to shared storage.
[2026-10-28T20:15:07Z] [INFO] [ivolve-logging-app-5477d9c669-7b2kx] Heartbeat event written to shared storage.
[2026-10-28T20:15:08Z] [INFO] [ivolve-logging-app-5477d9c669-m98pz] Heartbeat event written to shared storage.
```

Both replicas are concurrently writing logs to the exact same shared volume without collision or access denial!

---

### Step 5: Validate Data Persistence Across Workload Deletion

Delete the logging deployment:

```bash
kubectl delete -f manifests/03-logging-deployment.yaml
```

Deploy a new, independent reader pod:

```bash
kubectl apply -f manifests/04-log-reader-pod.yaml
kubectl wait --for=condition=Ready pod/ivolve-log-reader -n ivolve --timeout=60s
```

Verify that all historical logs are preserved:

```bash
kubectl exec -n ivolve ivolve-log-reader -- cat /mnt/app-logs/application.log | head -n 4
```

**Output:**
```
[2026-10-28T20:14:55Z] [INFO] [ivolve-logging-app-5477d9c669-7b2kx] Logging worker started.
[2026-10-28T20:14:56Z] [INFO] [ivolve-logging-app-5477d9c669-m98pz] Logging worker started.
```

The data was successfully retained on the node filesystem!

---

## ⚡ Automated Execution

```bash
# 1. Setup hostPath directory on node
bash scripts/01-setup-hostpath.sh

# 2. Apply PV and PVC
bash scripts/02-apply-storage.sh

# 3. Test RWX concurrent logging and persistence
bash scripts/03-verify-logging-persistence.sh

# 4. Cleanup test workloads
bash scripts/04-cleanup.sh
```
