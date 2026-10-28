# Lab 14: StatefulSet with Headless Service

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![StatefulSet](https://img.shields.io/badge/Workload-StatefulSet-blue.svg)](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
[![Headless Service](https://img.shields.io/badge/Networking-Headless_Service-orange.svg)](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
[![MySQL](https://img.shields.io/badge/Database-MySQL_8.0-4479A1.svg?logo=mysql&logoColor=white)](https://www.mysql.com/)

This lab demonstrates how to deploy production-ready stateful applications in Kubernetes using a **StatefulSet**, a **Headless Service**, **Persistent Volume Claim Templates**, dedicated node scheduling (**Taints, Tolerations, and Node Labels** from Lab 10), and decoupled configuration (**ConfigMaps and Secrets** from Lab 12).

---

## 🎯 Lab Objectives

- [x] **Create `ivolveDB` StatefulSet** in the `ivolve` namespace with **1 replica** running MySQL 8.0.
- [x] **Consume configuration and sensitive credentials**:
  - Injected non-sensitive variables (`DB_HOST`, `DB_USER`) from ConfigMap `ivolveCM`.
  - Injected credentials (`MYSQL_ROOT_PASSWORD`, `DB_PASSWORD`) from Secret `ivolveSecret`.
- [x] **Enforce dedicated node scheduling**:
  - Add **`nodeSelector`** with `project=ivolve` to pin the database to the designated worker node.
  - Add **`toleration`** matching `workload=ivolveApp:NoSchedule` to satisfy the node taint configured in Lab 10.
- [x] **Configure storage via PVC Template**:
  - Implement `volumeClaimTemplates` mounting `/var/lib/mysql` inside the database container.
- [x] **Write a Headless Service manifest**:
  - Named **`ivolveDBSvc`** (`clusterIP: None`) targeting port `3306` on the `ivolveDB` StatefulSet pods.
- [x] **Confirm database operations**:
  - Verify database readiness and execute queries using a MySQL client.
- [x] **Verify DNS resolution inside the cluster**:
  - Validate CoreDNS A records and SRV records for `ivolveDBSvc` and pod FQDN `ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local`.

---

## 💡 Architecture & Concepts

### 1. StatefulSet vs Deployment
Unlike Deployments which manage stateless, interchangeable pods, **StatefulSets** provide:
1. **Stable, Unique Network Identifiers**: Pods are named sequentially starting from index 0 (`ivolveDB-0`, `ivolveDB-1`, etc.).
2. **Dedicated Persistent Storage**: Each replica receives its own independent PVC instantiated from `volumeClaimTemplates` (`mysql-data-ivolveDB-0`).
3. **Ordered Deployment and Scaling**: Pods are created sequentially and guaranteed to terminate in reverse order.

```
+-------------------------------------------------------------------------------------------------+
|                                    KUBERNETES CLUSTER                                           |
|                                                                                                 |
|   +-----------------------------------------------------------------------------------------+   |
|   |                        CoreDNS Cluster Internal DNS Resolver                            |   |
|   +-----------------------------------------------------------------------------------------+   |
|          |                                                             |                        |
|          | Query: ivolveDBSvc                                          | Query:                 |
|          | (Resolves to Pod IP directly)                               | ivolveDB-0.ivolveDBSvc |
|          v                                                             v                        |
|   +-----------------------------------------------------------------------------------------+   |
|   |                           Headless Service: ivolveDBSvc                                 |   |
|   |                           (clusterIP: None, Port: 3306)                                 |   |
|   +-----------------------------------------------------------------------------------------+   |
|                                                |                                                |
|                                                v                                                |
|   +-----------------------------------------------------------------------------------------+   |
|   |                              Dedicated Worker Node                                      |   |
|   |                     Label: project=ivolve | Taint: workload=ivolveApp:NoSchedule        |   |
|   |                                                                                         |   |
|   |   +---------------------------------------------------------------------------------+   |   |
|   |   | Pod: ivolveDB-0 (StatefulSet: ivolveDB)                                         |   |   |
|   |   | - tolerations: workload=ivolveApp:NoSchedule                                    |   |   |
|   |   | - nodeSelector: project=ivolve                                                  |   |   |
|   |   |                                                                                 |   |   |
|   |   |   Env Variables:                                                                |   |   |
|   |   |   - DB_HOST, DB_USER <---------- ConfigMap 'ivolveCM'                           |   |   |
|   |   |   - MYSQL_ROOT_PASSWORD, DB_PASSWORD <--- Secret 'ivolveSecret'                 |   |   |
|   |   |                                                                                 |   |   |
|   |   |   VolumeMount:                                                                  |   |   |
|   |   |   - /var/lib/mysql <--- PVC: mysql-data-ivolveDB-0                              |   |   |
|   |   +---------------------------------------------------------------------------------+   |   |
|   +-----------------------------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------------------------+
```

### 2. Headless Service (`clusterIP: None`)
Standard Kubernetes Services assign a virtual IP (`ClusterIP`) that proxies traffic via `kube-proxy` across pod endpoints.
A **Headless Service** explicitly sets `clusterIP: None`. CoreDNS does not return a single service proxy IP; instead, it returns **A records pointing directly to the IP addresses of the underlying pods**. This enables direct client-to-pod routing and predictable database peering.

---

## 📁 Directory Structure

```
Lab-14-Kubernetes-StatefulSet-and-Headless-Service/
├── manifests/
│   ├── 00-mysql-pv.yaml                  # Local PV for bare-metal / static environments
│   ├── 01-headless-service.yaml          # Headless Service 'ivolveDBSvc' (clusterIP: None)
│   ├── 02-statefulset.yaml               # StatefulSet 'ivolveDB' (MySQL 8.0, 1 replica)
│   ├── 03-mysql-client-test-pod.yaml     # MySQL verification client pod
│   └── 04-dnsutils-pod.yaml              # CoreDNS inspection pod
├── scripts/
│   ├── 01-deploy-statefulset.sh          # Validates prerequisites & deploys database
│   ├── 02-verify-database-connection.sh  # Executes SQL checks & table mutations
│   ├── 03-verify-dns-resolution.sh       # Tests headless & pod DNS lookups
│   └── 04-cleanup.sh                     # Workload teardown script
└── README.md                             # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Ensure Prerequisites Are Active

Before deploying the StatefulSet, ensure the prerequisites from earlier labs are in place:

1. **Namespace & Quota** (Lab 11):
   ```bash
   kubectl get ns ivolve
   ```
2. **Worker Node Taint & Label** (Lab 10):
   ```bash
   # Ensure worker node has:
   # Label: project=ivolve
   # Taint: workload=ivolveApp:NoSchedule
   kubectl get nodes -l project=ivolve
   ```
3. **ConfigMap & Secret** (Lab 12):
   ```bash
   kubectl get configmap ivolveCM -n ivolve
   kubectl get secret ivolveSecret -n ivolve
   ```
4. **Storage Provisioning**:
   If dynamic storage provisioning is not enabled in the cluster, apply the 1Gi PersistentVolume:
   ```bash
   kubectl apply -f manifests/00-mysql-pv.yaml
   ```

---

### Step 2: Create the Headless Service `ivolveDBSvc`

Apply the Headless Service manifest:

```bash
kubectl apply -f manifests/01-headless-service.yaml
```

**Manifest (`manifests/01-headless-service.yaml`):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ivolveDBSvc
  namespace: ivolve
  labels:
    app: ivolve-db
spec:
  clusterIP: None
  ports:
    - port: 3306
      name: mysql
      targetPort: 3306
  selector:
    app: ivolve-db
```

Verify service creation:
```bash
kubectl get svc ivolveDBSvc -n ivolve
```

**Output:**
```
NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
ivolveDBSvc   ClusterIP   None         <none>        3306/TCP   10s
```

`CLUSTER-IP` is explicitly **`None`**.

---

### Step 3: Deploy the MySQL StatefulSet `ivolveDB`

Apply the StatefulSet manifest:

```bash
kubectl apply -f manifests/02-statefulset.yaml
```

**Manifest Highlights (`manifests/02-statefulset.yaml`):**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ivolveDB
  namespace: ivolve
spec:
  serviceName: "ivolveDBSvc"
  replicas: 1
  selector:
    matchLabels:
      app: ivolve-db
  template:
    metadata:
      labels:
        app: ivolve-db
    spec:
      nodeSelector:
        project: ivolve
      tolerations:
        - key: "workload"
          operator: "Equal"
          value: "ivolveApp"
          effect: "NoSchedule"
      containers:
        - name: mysql
          image: mysql:8.0
          ports:
            - containerPort: 3306
              name: mysql
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ivolveSecret
                  key: MYSQL_ROOT_PASSWORD
            - name: MYSQL_DATABASE
              value: "ivolve"
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  name: ivolveCM
                  key: DB_USER
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ivolveSecret
                  key: DB_PASSWORD
            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: ivolveCM
                  key: DB_HOST
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: mysql-data
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: ""
        resources:
          requests:
            storage: 1Gi
```

Monitor rollout until completion:
```bash
kubectl rollout status statefulset/ivolveDB -n ivolve
```

**Output:**
```
partitioned roll out complete: 1 new pods have been updated...
```

Verify pod status and node placement:
```bash
kubectl get pods -n ivolve -o wide
```

**Output:**
```
NAME         READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
ivolveDB-0   1/1     Running   0          45s   192.168.1.42   k8s-worker1   <none>           <none>
```

Notice that `ivolveDB-0` scheduled cleanly onto **`k8s-worker1`** (honoring `nodeSelector: project=ivolve` and tolerating `workload=ivolveApp:NoSchedule`).

Verify the auto-provisioned PVC:
```bash
kubectl get pvc -n ivolve
```

**Output:**
```
NAME                    STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-data-ivolveDB-0   Bound    mysql-data-pv   1Gi        RWO                           50s
```

---

### Step 4: Confirm Database Functionality with MySQL Client

#### Method A: Direct In-Pod Validation
Test server responsiveness using `mysqladmin ping`:

```bash
kubectl exec -n ivolve ivolveDB-0 -- mysqladmin -u root -p"ivolveRootPass2026!" ping
```

**Output:**
```
mysqld is alive
```

Test application user permissions:
```bash
kubectl exec -n ivolve ivolveDB-0 -- mysql -u ivolveuser -p"ivolveUserPass2026!" -D ivolve -e "SHOW TABLES;"
```

#### Method B: Cluster-Internal Client Pod Execution
Deploy the verification client (`manifests/03-mysql-client-test-pod.yaml`):

```bash
kubectl apply -f manifests/03-mysql-client-test-pod.yaml
kubectl wait --for=condition=Ready pod/mysql-client-test -n ivolve --timeout=60s
kubectl logs -n ivolve mysql-client-test
```

**Output:**
```
Testing MySQL connectivity to ivolveDBSvc...
+----+-------------------+---------------------+
| id | pod_name          | verified_at         |
+----+-------------------+---------------------+
|  1 | mysql-client-test | 2026-10-28 20:25:10 |
+----+-------------------+---------------------+
+------------------+
| Tables_in_ivolve |
+------------------+
| cluster_verification |
+------------------+
MySQL verification query completed successfully!
```

---

### Step 5: Verify DNS Resolution Inside the Cluster

Deploy `dnsutils` to inspect CoreDNS behavior:

```bash
kubectl apply -f manifests/04-dnsutils-pod.yaml
kubectl wait --for=condition=Ready pod/dnsutils -n ivolve --timeout=60s
```

#### 1. Resolve Headless Service:
```bash
kubectl exec -i -n ivolve dnsutils -- nslookup ivolveDBSvc
```

**Output:**
```
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   ivolveDBSvc.ivolve.svc.cluster.local
Address: 192.168.1.42
```

The DNS query directly returns the Pod IP (`192.168.1.42`), proving that traffic avoids intermediate proxy hops!

#### 2. Resolve StatefulSet Pod FQDN:
```bash
kubectl exec -i -n ivolve dnsutils -- nslookup ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local
```

**Output:**
```
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local
Address: 192.168.1.42
```

Each StatefulSet pod has a deterministic, globally resolvable domain name (`<pod-name>.<service-name>.<namespace>.svc.cluster.local`).

---

## ⚡ Automated Execution

Run the complete deployment and test sequence:

```bash
# 1. Deploy Headless Service and StatefulSet
bash scripts/01-deploy-statefulset.sh

# 2. Verify Database Connection
bash scripts/02-verify-database-connection.sh

# 3. Verify Headless DNS Resolution
bash scripts/03-verify-dns-resolution.sh

# 4. Teardown test pods
bash scripts/04-cleanup.sh
```
