# Lab 18: Node-Wide Pod Management with DaemonSet

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-v2.54-E6522C.svg?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-v11.2-F46800.svg?logo=grafana&logoColor=white)](https://grafana.com/)
[![DaemonSet](https://img.shields.io/badge/Workload-DaemonSet-blue.svg)](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

This lab demonstrates how to implement cluster-wide infrastructure observability in Kubernetes using a **DaemonSet** for **Prometheus Node Exporter**, coupled with **Prometheus Server**, **Alertmanager**, and **Grafana** deployed within a dedicated `monitoring` namespace.

---

## 🎯 Lab Objectives

- [x] **Create `monitoring` namespace** for complete isolation of cluster observability tools.
- [x] **Deploy Prometheus** in the `monitoring` namespace with cluster RBAC discovery.
- [x] **Deploy Alertmanager** in the `monitoring` namespace with alert routing rules.
- [x] **Deploy Grafana** in the `monitoring` namespace with auto-provisioned Prometheus datasource.
- [x] **Deploy a DaemonSet for Prometheus `node-exporter`**:
  - Run with host filesystem and process isolation access (`/proc`, `/sys`, `/`).
  - Configured with tolerations to ensure node-exporter runs on **all** nodes (master/control-plane and tainted workers).
- [x] **Validate DaemonSet Scheduling**: Confirm that exactly one `node-exporter` pod is scheduled on each node.
- [x] **Confirm Metrics Exposure**: Access `<node_IP>:9100/metrics` to verify hardware and OS metric generation.
- [x] **Configure Prometheus Scraping**: Connect Prometheus to collect data automatically from the node-exporter endpoints.
- [x] **Configure Grafana Dashboard**: Connect Grafana to Prometheus and visualize Kubernetes host metrics using community dashboard **1860** (*Node Exporter Full*).

---

## 💡 Architecture & Metrics Flow

```
+---------------------------------------------------------------------------------------------------+
|                                     KUBERNETES CLUSTER                                            |
|                                                                                                   |
|    +-----------------------------+       +-----------------------------+                          |
|    | Control Plane (k8s-master)  |       | Worker Node (k8s-worker1)   |                          |
|    |                             |       |                             |                          |
|    | [ Pod: node-exporter-cp ]   |       | [ Pod: node-exporter-w1 ]   | (DaemonSet guarantee:    |
|    |   HostPort: 9100/metrics    |       |   HostPort: 9100/metrics    |  1 pod per cluster node) |
|    +-----------------------------+       +-----------------------------+                          |
|                   \                                     /                                         |
|                    \        Scrape Interval (15s)      /                                          |
|                     v                                 v                                           |
|       +-------------------------------------------------------------+                             |
|       |                     'monitoring' NAMESPACE                  |                             |
|       |                                                             |                             |
|       |   +-----------------------------------------------------+   |                             |
|       |   | Prometheus Server (:9090)                           |   |                             |
|       |   | - TSDB Storage                                      |   |                             |
|       |   | - Kubernetes Service Discovery                      |   |                             |
|       |   | - Alert Rules: HighNodeCPU, HighNodeMemory          |   |                             |
|       |   +-----------------------------------------------------+   |                             |
|       |                   /                                 \       |                             |
|       |     Alert Trigger/                                   \ Query|                             |
|       |                 v                                     v     |                             |
|       |   +---------------------------+       +------------------+  |                             |
|       |   | Alertmanager (:9093)      |       | Grafana (:3000)  |  |                             |
|       |   | NodePort: 30093           |       | NodePort: 30080  |  |                             |
|       |   | Grouping & Notification   |       | Dashboard: 1860  |  |                             |
|       |   +---------------------------+       +------------------+  |                             |
|       +-------------------------------------------------------------+                             |
+---------------------------------------------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-18-Kubernetes-Prometheus-Grafana-DaemonSet/
├── manifests/
│   ├── 01-monitoring-namespace.yaml             # Dedicated 'monitoring' namespace
│   ├── 02-node-exporter-daemonset.yaml          # DaemonSet running node-exporter on every node
│   ├── 03-node-exporter-service.yaml            # Headless discovery service for endpoints
│   ├── 04-prometheus-configmap.yaml             # Scrape configs & alert rules
│   ├── 05-prometheus-deployment-and-service.yaml# Prometheus Server + RBAC + NodePort 30090
│   ├── 06-alertmanager-deployment-and-service.yaml # Alertmanager + NodePort 30093
│   ├── 07-grafana-datasource-and-dashboards.yaml   # Auto-provisioned Prometheus datasource
│   └── 08-grafana-deployment-and-service.yaml      # Grafana UI + NodePort 30080
├── scripts/
│   ├── 01-deploy-monitoring.sh                  # Deploys full monitoring stack
│   ├── 02-verify-node-exporter.sh               # Validates DaemonSet scheduling & metrics
│   ├── 03-verify-metrics-and-prometheus.sh      # PromQL query & target verification
│   └── 04-cleanup.sh                            # Teardown script
└── README.md                                    # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Deploy Full Monitoring Stack

Execute the deployment script to create all resources:

```bash
bash scripts/01-deploy-monitoring.sh
```

**Manifest Highlights (`manifests/02-node-exporter-daemonset.yaml`):**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: node-exporter
  template:
    spec:
      hostNetwork: true
      hostPID: true
      tolerations:
        - operator: "Exists"
          effect: "NoSchedule"
        - operator: "Exists"
          effect: "NoExecute"
      containers:
        - name: node-exporter
          image: prom/node-exporter:v1.8.2
          ports:
            - containerPort: 9100
              hostPort: 9100
```

Verify rollout across pods:
```bash
kubectl get pods -n monitoring -o wide
```

**Output:**
```
NAME                             READY   STATUS    RESTARTS   AGE   IP              NODE
alertmanager-5f778d9b5-c9x2v     1/1     Running   0          45s   192.168.1.61    k8s-worker1
grafana-7489569b6b-q7w8x         1/1     Running   0          45s   192.168.1.62    k8s-worker1
node-exporter-h5x2z              1/1     Running   0          45s   192.168.0.10    k8s-master
node-exporter-z48nm              1/1     Running   0          45s   192.168.0.20    k8s-worker1
prometheus-85c8d64bf6-9vpk4      1/1     Running   0          45s   192.168.1.63    k8s-worker1
```

---

### Step 2: Validate DaemonSet Scheduling on Each Node

Verify that the number of scheduled pods matches total cluster nodes:

```bash
kubectl get daemonset node-exporter -n monitoring
```

**Output:**
```
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   2         2         2       2            2           <none>          2m
```

---

### Step 3: Confirm Metrics Exposure via `<node_IP>:9100/metrics`

Query the Node Exporter metrics endpoint directly on node IP:

```bash
curl -s http://192.168.0.20:9100/metrics | grep -E "^node_cpu_seconds_total|^node_memory_MemTotal_bytes" | head -n 4
```

**Output:**
```
node_cpu_seconds_total{cpu="0",mode="idle"} 12480.52
node_cpu_seconds_total{cpu="0",mode="system"} 320.14
node_cpu_seconds_total{cpu="0",mode="user"} 450.81
node_memory_MemTotal_bytes 4128538624
```

---

### Step 4: Verify Prometheus Target Discovery & PromQL

Query Prometheus API to confirm that `node-exporter` targets are in state `UP`:

```bash
PROM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n monitoring "${PROM_POD}" -- wget -qO- http://localhost:9090/api/v1/targets
```

**Output:**
```json
{"status":"success","data":{"activeTargets":[{"discoveredLabels":{...},"labels":{"instance":"192.168.0.20:9100","job":"node-exporter"},"health":"up"}]}}
```

Test CPU utilization query:
```bash
# PromQL: Node CPU Utilization %
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
```

---

### Step 5: Configure Grafana Dashboard

1. Access Grafana UI at `http://<node_IP>:30080` (Default credentials: `admin` / `admin123`).
2. Verify that the **Prometheus** datasource is pre-configured and tests green.
3. Import Community Dashboard **1860** (*Node Exporter Full*):
   - Navigate to **Dashboards** -> **New** -> **Import**.
   - Enter ID `1860` and click **Load**.
   - Select datasource `Prometheus` and click **Import**.
4. Real-time CPU, RAM, Network I/O, and Disk metrics will render immediately!

---

## ⚡ Automated Verification

```bash
# 1. Deploy Monitoring Stack
bash scripts/01-deploy-monitoring.sh

# 2. Validate DaemonSet Scheduling & Node Metrics Exposure
bash scripts/02-verify-node-exporter.sh

# 3. Verify Prometheus Scraping & Querying
bash scripts/03-verify-metrics-and-prometheus.sh

# 4. Teardown
bash scripts/04-cleanup.sh
```
