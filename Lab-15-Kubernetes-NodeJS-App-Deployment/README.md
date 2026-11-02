# Lab 15: Node.js Application Deployment with ClusterIP Service

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker_Hub-zeyadmvtr%2Fivolve--app-2496ED.svg?logo=docker&logoColor=white)](https://hub.docker.com/r/zeyadmvtr/ivolve-app)
[![Node.js](https://img.shields.io/badge/Node.js-Express-339933.svg?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Service](https://img.shields.io/badge/Service-ClusterIP-orange.svg)](https://kubernetes.io/docs/concepts/services-networking/service/)

This lab demonstrates how to deploy a multi-replica containerized Node.js web application (`zeyadmvtr/ivolve-app:latest` from Lab 8) into a Kubernetes cluster using a **Deployment**, a **ClusterIP Service**, an **Init Container** for database bootstrapping, decoupled configuration (**ConfigMaps and Secrets** from Lab 12), shared logging storage (**PersistentVolume** from Lab 13), and dedicated node isolation (**Taints and Node Labels** from Lab 10).

---

## 🎯 Lab Objectives

- [x] **Create a Deployment named `ivolveApp`** in the `ivolve` namespace with **2 replicas**.
- [x] **Use the custom Docker image** published to Docker Hub in Lab 8: `zeyadmvtr/ivolve-app:latest`.
- [x] **Consume environment variables** from existing ConfigMap (`ivolveCM`) and Secret (`ivolveSecret`):
  - `DB_HOST`: Hostname of MySQL Headless Service (`ivolveDBSvc`).
  - `DB_USER`: Application database user (`ivolveuser`).
  - `DB_PASSWORD`: Decrypted password for `ivolveuser`.
  - `DB_NAME`: Database name (`ivolve`).
- [x] **Enforce dedicated node scheduling**:
  - Add **`nodeSelector`** targeting nodes with label `project=ivolve`.
  - Add **`toleration`** matching `workload=ivolveApp:NoSchedule`.
- [x] **Attach Persistent Storage**:
  - Mount the `ivolvePVC` PersistentVolumeClaim created in Lab 13 at `/app/logs` to persist Express HTTP access logs (`access.log`).
- [x] **Implement an Init Container**:
  - Uses `mysql:8.0` image to connect to MySQL (`ivolveDBSvc`), verify database readiness, create the `ivolve` database if not present, and grant required permissions to `ivolveuser`.
  - Passes connection parameters to the init container via `ivolveCM` and `ivolveSecret`.
- [x] **Create a ClusterIP Service named `ivolveAppSvc`** in the `ivolve` namespace to distribute HTTP traffic across the 2 application replicas on port `3000`.
- [x] **Verify Database Operations & User Privileges**:
  - Manually connect to MySQL to verify database creation and user grants.
- [x] **Verify Node.js Connectivity & Logs**:
  - Inspect pod logs to confirm that the Node.js application successfully connects to MySQL, initializes tables, and handles requests.

---

## 💡 Architecture & Workflow

```
+---------------------------------------------------------------------------------------------------+
|                                     KUBERNETES CLUSTER                                            |
|                                                                                                   |
|     +-----------------------------------------------------------------------------------------+   |
|     |                       ClusterIP Service: ivolveAppSvc (Port 3000)                       |   |
|     |                    Internal Load Balancer for Frontend / Microservices                  |   |
|     +-----------------------------------------------------------------------------------------+   |
|                                    /                                   \                          |
|                      Round-Robin  /                                     \  Round-Robin            |
|                                  v                                       v                        |
|   +---------------------------------------------+   +-----------------------------------------+   |
|   | Pod: ivolveApp-replica-1                    |   | Pod: ivolveApp-replica-2                |   |
|   |                                             |   |                                         |   |
|   | 1. Init Container (mysql:8.0):              |   | 1. Init Container (mysql:8.0):          |   |
|   |    - Waits for ivolveDBSvc:3306             |   |    - Verifies DB readiness              |   |
|   |    - CREATE DATABASE IF NOT EXISTS ivolve   |   |    - Ensures grants for ivolveuser      |   |
|   |    - GRANT ALL on ivolve.* TO ivolveuser    |   |                                         |   |
|   |                                             |   |                                         |   |
|   | 2. App Container (zeyadmvtr/ivolve-app):    |   | 2. App Container (zeyadmvtr/ivolve-app):|   |
|   |    - Env from ivolveCM & ivolveSecret       |   |    - Env from ivolveCM & ivolveSecret   |   |
|   |    - Connects to MySQL at ivolveDBSvc:3306  |   |    - Connects to MySQL at ivolveDBSvc   |   |
|   |    - Writes Morgan logs -> /app/logs        |   |    - Writes Morgan logs -> /app/logs    |   |
|   |                                             |   |                                         |   |
|   | Node Placement:                             |   | Node Placement:                         |   |
|   |    - nodeSelector: project=ivolve           |   |    - nodeSelector: project=ivolve       |   |
|   |    - tolerations: workload=ivolveApp        |   |    - tolerations: workload=ivolveApp    |   |
|   +---------------------------------------------+   +-----------------------------------------+   |
|                          \                                     /                                  |
|                           \       Mounts Volume Claim         /                                   |
|                            +---------------------------------+                                    |
|                                             |                                                     |
|                                             v                                                     |
|                     +-----------------------------------------------+                             |
|                     | PersistentVolumeClaim: ivolvePVC (Lab 13)     |                             |
|                     | Backing PV: ivolvePV (ReadWriteMany hostPath) |                             |
|                     | Storing /app/logs/access.log across replicas  |                             |
|                     +-----------------------------------------------+                             |
|                                             |                                                     |
|                                             v                                                     |
|                     +-----------------------------------------------+                             |
|                     | Headless MySQL DB: ivolveDB-0 (Lab 14)        |                             |
|                     | Service: ivolveDBSvc:3306                     |                             |
|                     +-----------------------------------------------+                             |
+---------------------------------------------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-15-Kubernetes-NodeJS-App-Deployment/
├── manifests/
│   ├── 01-clusterip-service.yaml         # ClusterIP service 'ivolveAppSvc' (Port 3000)
│   ├── 02-deployment.yaml                # 2-replica Deployment with init container & volume mount
│   ├── 03-manual-mysql-verify-pod.yaml   # Verification pod checking MySQL DB & grants
│   └── 04-curl-client-pod.yaml           # Client pod testing HTTP endpoints & generating access logs
├── scripts/
│   ├── 01-deploy-app.sh                  # Deploys service & deployment and waits for rollout
│   ├── 02-verify-mysql-db-and-user.sh    # Validates DB creation and ivolveuser permissions
│   ├── 03-check-app-logs.sh              # Checks pod logs and shared persistent access logs
│   └── 04-cleanup.sh                     # Removes test pods
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Create ClusterIP Service `ivolveAppSvc`

Apply the ClusterIP Service manifest:

```bash
kubectl apply -f manifests/01-clusterip-service.yaml
```

**Manifest (`manifests/01-clusterip-service.yaml`):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ivolveAppSvc
  namespace: ivolve
  labels:
    app: ivolve-app
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 3000
      targetPort: 3000
      protocol: TCP
  selector:
    app: ivolve-app
```

Verify service creation:
```bash
kubectl get svc ivolveAppSvc -n ivolve
```

**Output:**
```
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
ivolveAppSvc   ClusterIP   10.108.140.210   <none>        3000/TCP   12s
```

---

### Step 2: Deploy `ivolveApp` with Init Container and Persistent Volume

Apply the deployment manifest:

```bash
kubectl apply -f manifests/02-deployment.yaml
```

**Key Manifest Configurations (`manifests/02-deployment.yaml`):**
1. **Node Placement**:
   ```yaml
   nodeSelector:
     project: ivolve
   tolerations:
     - key: "workload"
       operator: "Equal"
       value: "ivolveApp"
       effect: "NoSchedule"
   ```
2. **Init Container**:
   ```yaml
   initContainers:
     - name: init-mysql-db
       image: mysql:8.0
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
       command:
         - sh
         - -c
         - |
           until mysql -h "${DB_HOST}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; do
             echo "Waiting for MySQL server at ${DB_HOST}:3306..."
             sleep 2
           done
           mysql -h "${DB_HOST}" -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
           CREATE DATABASE IF NOT EXISTS ivolve;
           CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
           ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
           GRANT ALL PRIVILEGES ON ivolve.* TO '${DB_USER}'@'%';
           FLUSH PRIVILEGES;
           EOF
   ```
3. **Application Container & Storage**:
   ```yaml
   containers:
     - name: ivolve-app
       image: zeyadmvtr/ivolve-app:latest
       ports:
         - containerPort: 3000
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
         - name: DB_PASSWORD
           valueFrom:
             secretKeyRef:
               name: ivolveSecret
               key: DB_PASSWORD
         - name: DB_NAME
           value: "ivolve"
         - name: PORT
           value: "3000"
       volumeMounts:
         - name: app-logs-volume
           mountPath: /app/logs
   volumes:
     - name: app-logs-volume
       persistentVolumeClaim:
         claimName: ivolvePVC
   ```

Monitor the deployment rollout:
```bash
kubectl rollout status deployment/ivolveApp -n ivolve
```

**Output:**
```
Waiting for deployment "ivolveApp" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "ivolveApp" rollout to finish: 1 of 2 updated replicas are available...
deployment "ivolveApp" successfully rolled out
```

Check running pods in `ivolve` namespace:
```bash
kubectl get pods -n ivolve -o wide
```

**Output:**
```
NAME                         READY   STATUS    RESTARTS   AGE   IP              NODE          NOMINATED NODE   READINESS GATES
ivolveApp-789cf94ddb-5v2p9   1/1     Running   0          40s   192.168.1.55    k8s-worker1   <none>           <none>
ivolveApp-789cf94ddb-r8m2t   1/1     Running   0          40s   192.168.1.56    k8s-worker1   <none>           <none>
ivolveDB-0                   1/1     Running   0          10m   192.168.1.42    k8s-worker1   <none>           <none>
```

> **Quota Compliance**: Notice that the 3 running pods (`ivolveDB-0` + 2 `ivolveApp` replicas) strictly honor the 3-pod ResourceQuota limit set in Lab 11!

---

### Step 3: Connect to MySQL Manually to Verify DB and Privileges

Connect directly to MySQL to confirm database initialization:

```bash
kubectl exec -n ivolve ivolveDB-0 -- mysql -u ivolveuser -p"ivolveUserPass2026!" -D ivolve -e "
  SHOW DATABASES;
  SHOW GRANTS FOR 'ivolveuser'@'%';
  SHOW TABLES;
"
```

**Output:**
```
Database
--------
information_schema
ivolve
performance_schema

Grants for ivolveuser@%
---------------------------------------------------------------------------------
GRANT USAGE ON *.* TO `ivolveuser`@`%`
GRANT ALL PRIVILEGES ON `ivolve`.* TO `ivolveuser`@`%`

Tables_in_ivolve
----------------
products
```

The database `ivolve` exists, the user `ivolveuser` has full permissions, and the application's `products` table is present!

---

### Step 4: Verify Application Logs and DB Connectivity

Check container console logs for successful database initialization:

```bash
kubectl logs -n ivolve deployment/ivolveApp -c ivolve-app --tail=20
```

**Output:**
```
Attempt 1: Connecting to MySQL...
Server is running on http://localhost:3000
Database connection established successfully.
Products table seeded with initial inventory.
```

---

### Step 5: Verify Service Traffic Distribution and Persistent Storage

Send test HTTP requests via `ivolveAppSvc:3000`:

```bash
kubectl apply -f manifests/04-curl-client-pod.yaml
kubectl wait --for=condition=Ready pod/ivolve-client-tester -n ivolve --timeout=60s
kubectl logs -n ivolve ivolve-client-tester
```

**Output:**
```
Testing HTTP communication to ivolveAppSvc:3000...
🎯 iVolve web app is working! Keep calm and code on! 🚀
✨ iVolve web app is ready to rock and roll! 🎸
<!DOCTYPE html><html><head><title>iVolve Store</title>...</html>
```

Inspect the persistent access logs at `/app/logs/access.log`:

```bash
POD_NAME=$(kubectl get pods -n ivolve -l app=ivolve-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ivolve "${POD_NAME}" -c ivolve-app -- cat /app/logs/access.log | tail -n 5
```

**Output:**
```
::ffff:192.168.1.60 - - [02/Nov/2026:18:25:12 +0000] "GET /health HTTP/1.1" 200 62 "-" "curl/8.5.0"
::ffff:192.168.1.60 - - [02/Nov/2026:18:25:13 +0000] "GET /ready HTTP/1.1" 200 58 "-" "curl/8.5.0"
::ffff:192.168.1.60 - - [02/Nov/2026:18:25:14 +0000] "GET / HTTP/1.1" 200 2415 "-" "curl/8.5.0"
```

---

## ⚡ Automated Execution

```bash
# 1. Deploy Service and Application
bash scripts/01-deploy-app.sh

# 2. Verify MySQL Database and Privileges
bash scripts/02-verify-mysql-db-and-user.sh

# 3. Check Application Logs and Persistent Access Logs
bash scripts/03-check-app-logs.sh

# 4. Clean up test pods
bash scripts/04-cleanup.sh
```
