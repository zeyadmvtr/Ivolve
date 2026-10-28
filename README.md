# iVolve DevOps & Cloud Training Labs

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://www.oracle.com/java/)
[![Maven](https://img.shields.io/badge/Maven-3.8+-blue.svg)](https://maven.apache.org/)
[![Gradle](https://img.shields.io/badge/Gradle-8+-02303A.svg)](https://gradle.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED.svg)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-v2+-blue.svg)](https://docs.docker.com/compose/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1.svg)](https://www.mysql.com/)
[![Trivy](https://img.shields.io/badge/Trivy-Security_Auditing-1904DA.svg)](https://trivy.dev/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB.svg)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2F20_LTS-339933.svg)](https://nodejs.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg)](https://kubernetes.io/)
[![Calico](https://img.shields.io/badge/Calico_CNI-v3.28-FFA500.svg)](https://www.tigera.io/project-calico/)

This repository contains complete codebases, multi-stage Dockerfiles, security auditing configurations, environment setups, orchestration manifests, and detailed documentation for the **iVolve** engineering labs.

---

## 📚 Table of Contents

- [Repository Structure](#-repository-structure)
- [Lab 1: Java Application with Maven](#-lab-1-building-and-packaging-java-application-with-maven)
- [Lab 2: Application with Gradle](#-lab-2-building-and-packaging-application-with-gradle)
- [Lab 3: Docker Containerization for Java App](#-lab-3-creating-a-docker-image-for-a-java-application)
- [Lab 4: Docker Image Optimization and Export/Load](#-lab-4-docker-image-optimization-and-exportload)
- [Lab 5: Docker Vulnerability Scanning with Trivy](#-lab-5-docker-image-vulnerability-scanning-with-trivy)
- [Lab 6: Environment Variables and Resource Management](#-lab-6-docker-environment-variables-and-resource-management)
- [Lab 7: Multi-Network Microservices, Volumes, and Bind Mounts](#-lab-7-multi-network-microservices-volumes-and-bind-mounts)
- [Lab 8: Node.js and MySQL Stack with Docker Compose](#-lab-8-containerized-nodejs-and-mysql-stack-using-docker-compose)
- [Lab 9: Deploy Kubernetes Cluster using Kubeadm](#-lab-9-deploy-kubernetes-cluster-using-kubeadm)
- [Lab 10: Node Isolation Using Taints and Labels in Kubernetes](#-lab-10-node-isolation-using-taints-and-labels-in-kubernetes)
- [Lab 11: Namespace Management and Resource Quota Enforcement](#-lab-11-namespace-management-and-resource-quota-enforcement)
- [Lab 12: Managing Configuration and Sensitive Data with ConfigMaps and Secrets](#-lab-12-managing-configuration-and-sensitive-data-with-configmaps-and-secrets)
- [Lab 13: Persistent Storage Setup for Application Logging](#-lab-13-persistent-storage-setup-for-application-logging)
- [Lab 14: StatefulSet with Headless Service](#-lab-14-statefulset-with-headless-service)

---

## 🗂️ Repository Structure

```
.
├── Lab-1-Maven/                           # Lab 1: Java packaging with Apache Maven
│   ├── pom.xml
│   ├── README.md
│   └── src/
│
├── Lab-2-Gradle/                          # Lab 2: Application packaging with Gradle
│   ├── build.gradle
│   ├── settings.gradle
│   ├── README.md
│   └── src/
│
├── Lab-3-Docker/                          # Lab 3: Containerization (Single vs Multi-Stage)
│   ├── Dockerfile.part1                   # Part 1: Maven build inside container
│   ├── Dockerfile.part2                   # Part 2: Lightweight JRE runtime
│   ├── COMPARISON.md                      # Detailed comparison report (sizes, layers, security)
│   ├── README.md
│   ├── part1-build-inside-docker/
│   └── part2-build-locally/
│
├── Lab-4-Docker-Optimization/             # Lab 4: Multi-stage optimization & image tar export
│   ├── Dockerfile                         # Multi-stage optimized Dockerfile (image2)
│   ├── Dockerfile.original                # Single-stage fat Dockerfile (image1)
│   ├── pom.xml
│   ├── README.md
│   └── src/
│
├── Lab-5-Docker-Trivy-Security/           # Lab 5: Security scanning & CVE remediation with Trivy
│   ├── Dockerfile.v1                      # Vulnerable image (node:18-bullseye)
│   ├── Dockerfile.v2                      # Remediated image (node:20-alpine)
│   ├── REMEDIATION.md                     # Deep-dive CVE analysis & remediation report
│   ├── README.md
│   ├── app.js
│   ├── package.json
│   ├── v1-vulnerable/
│   └── v2-remediated/
│
├── Lab-6-Docker-Env-Resources/            # Lab 6: Docker environment variables & resource limits
│   ├── Dockerfile                         # Standard Python 3.12-slim Dockerfile
│   ├── Dockerfile.hardcoded               # Dockerfile with baked-in ENV variables
│   ├── env.txt                            # Environment variable file for container2
│   ├── app.py                             # Flask application
│   ├── requirements.txt
│   └── README.md
│
├── Lab-7-Multi-Network-Microservices/     # Lab 7: Multi-network microservices, volumes & bind mounts
│   ├── frontend/                          # Web tier container
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── backend/                           # API & data persistence tier container
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── notification/                      # Notification logging tier container
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── backend-data/                      # Host bind mount directory (messages.json)
│   ├── run-lab7.sh                        # Automated execution script (Linux/WSL)
│   ├── run-lab7.ps1                       # Automated execution script (Windows PowerShell)
│   └── README.md
│
├── Lab-8-Docker-Compose-Node-MySQL/       # Lab 8: Full-stack Node.js + MySQL orchestration
│   ├── frontend/                          # Static UI assets
│   ├── Dockerfile                         # Node.js 18-alpine Dockerfile
│   ├── docker-compose.yml                 # Compose file for app, db, network, volumes
│   ├── package.json
│   ├── server.js                          # Express app with MySQL connection & retry logic
│   ├── db.js
│   └── README.md
│
├── Lab-9-Kubernetes-Kubeadm-Cluster/      # Lab 9: Multi-node K8s cluster deployment via Kubeadm
│   ├── manifests/                         # Calico CNI, kubeadm-config, and smoke test specs
│   ├── scripts/                           # Containerd, kubeadm, init, calico, join & verify scripts
│   ├── Vagrantfile                        # Automated local multi-node cluster environment
│   └── README.md
│
├── Lab-10-Kubernetes-Taints-and-Labels/   # Lab 10: Node isolation using taints and labels
│   ├── manifests/                         # Untolerated, tolerated & dedicated nodeSelector specs
│   ├── scripts/                           # Apply, test isolation & cleanup scripts
│   └── README.md
│
├── Lab-11-Kubernetes-Namespace-and-ResourceQuota/ # Lab 11: Namespace & ResourceQuota enforcement
│   ├── manifests/                         # Namespace 'ivolve', ivolveQuota (pods: 3), test workloads
│   ├── scripts/                           # Setup, verify quota enforcement & cleanup scripts
│   └── README.md
│
├── Lab-12-Kubernetes-ConfigMaps-and-Secrets/     # Lab 12: ConfigMaps and Base64-encoded Secrets
│   ├── manifests/                         # ConfigMap 'ivolveCM', Secret 'ivolveSecret', consumer pod
│   ├── scripts/                           # Encode & apply, verify injection & cleanup scripts
│   └── README.md
│
├── Lab-13-Kubernetes-Persistent-Storage/          # Lab 13: Persistent storage for application logging
│   ├── manifests/                         # PV 'ivolvePV' (1Gi, RWX, hostPath), PVC 'ivolvePVC', log app
│   ├── scripts/                           # Setup host directory, apply storage, test persistence
│   └── README.md
│
├── Lab-14-Kubernetes-StatefulSet-and-Headless-Service/ # Lab 14: StatefulSet with Headless Service
│   ├── manifests/                         # Headless service 'ivolveDBSvc', StatefulSet 'ivolveDB', test pods
│   ├── scripts/                           # Deploy, verify DB connectivity & verify DNS resolution
│   └── README.md
│
└── README.md
```

---

## 🛠️ Lab 1: Building and Packaging Java Application with Maven

👉 **Guide**: [`Lab-1-Maven/README.md`](Lab-1-Maven/README.md)

- **Artifact**: `target/calculator.jar`
- **Key Commands**:
  ```bash
  cd Lab-1-Maven
  mvn test
  mvn clean package
  java -jar target/calculator.jar
  ```

---

## 🐘 Lab 2: Building and Packaging Application with Gradle

👉 **Guide**: [`Lab-2-Gradle/README.md`](Lab-2-Gradle/README.md)

- **Artifact**: `build/libs/calculator.jar`
- **Key Commands**:
  ```bash
  cd Lab-2-Gradle
  gradle test
  gradle build
  java -jar build/libs/calculator.jar
  ```

---

## 🐳 Lab 3: Creating a Docker Image for a Java Application

👉 **Guide**: [`Lab-3-Docker/README.md`](Lab-3-Docker/README.md) | **Analysis**: [`Lab-3-Docker/COMPARISON.md`](Lab-3-Docker/COMPARISON.md)

- **Part 1 (Build Inside Docker - `app1`)**: Single-stage Maven image (~750 MB)
- **Part 2 (Build Locally - `app2`)**: Minimal JRE image with pre-built JAR (~240 MB)
- **Key Commands**:
  ```bash
  cd Lab-3-Docker
  # Part 1
  docker build -f Dockerfile.part1 -t app1 .
  # Part 2
  mvn clean package && docker build -f Dockerfile.part2 -t app2 .
  ```

---

## ⚡ Lab 4: Docker Image Optimization and Export/Load

👉 **Guide**: [`Lab-4-Docker-Optimization/README.md`](Lab-4-Docker-Optimization/README.md)

- **Optimizations**: Multi-stage build (Maven Alpine ➔ JRE Alpine), non-root user (`appuser`).
- **Results**: Image size reduced from **~430 MB (`image1`)** to **~185 MB (`image2`)** (~57% smaller).
- **Export & Import**:
  ```bash
  cd Lab-4-Docker-Optimization
  docker build -t image2 .
  docker save -o lab-image.tar image2
  docker rmi image2
  docker load -i lab-image.tar
  ```

---

## 🛡️ Lab 5: Docker Vulnerability Scanning with Trivy

👉 **Guide**: [`Lab-5-Docker-Trivy-Security/README.md`](Lab-5-Docker-Trivy-Security/README.md) | **Analysis**: [`Lab-5-Docker-Trivy-Security/REMEDIATION.md`](Lab-5-Docker-Trivy-Security/REMEDIATION.md)

- **Audit**: Detected multiple HIGH and CRITICAL vulnerabilities in `node:18-bullseye` and `express: 4.18.2`.
- **Remediation**:
  - Base Image: Upgraded to `node:20-alpine`.
  - Dependencies: Updated Express to `^4.21.2`.
  - Permissions: Dropped privileges to non-root `USER node`.
- **Result**: **0 HIGH** and **0 CRITICAL** vulnerabilities in `ivolve-app:v2`.
- **Key Commands**:
  ```bash
  cd Lab-5-Docker-Trivy-Security
  # Scan & generate HTML audit report
  trivy image --severity HIGH,CRITICAL -o report-v1.html trivy-lab:v1
  # Verify remediation
  trivy image --severity HIGH,CRITICAL -o report-v2.html ivolve-app:v2
  ```

---

## ⚙️ Lab 6: Docker Environment Variables and Resource Management

👉 **Guide**: [`Lab-6-Docker-Env-Resources/README.md`](Lab-6-Docker-Env-Resources/README.md)

- **Application**: Python 3.12 Flask API responding dynamically to `APP_NAME` and `APP_ENV`.
- **Patterns Demonstrated**:
  1. **Inline & Resources**:
     ```bash
     docker run -d --name container1 -p 5000:5000 \
       -e APP_NAME=iVolveApp1 -e APP_ENV=stg \
       --cpus="1.0" --memory="256m" ivolve1
     ```
  2. **Environment File (`env.txt`)**:
     ```bash
     docker run -d --name container2 -p 5000:5000 --env-file env.txt ivolve1
     ```
  3. **Hardcoded in Dockerfile**:
     ```bash
     docker build -f Dockerfile.hardcoded -t ivolve3 .
     docker run -d --name container3 -p 5000:5000 ivolve3
     ```
  4. **Resource Monitoring**:
     ```bash
     docker stats container1 --no-stream
     ```

---

## 🌐 Lab 7: Multi-Network Microservices, Volumes, and Bind Mounts

👉 **Guide**: [`Lab-7-Multi-Network-Microservices/README.md`](Lab-7-Multi-Network-Microservices/README.md)

- **Services**: Frontend (`port 3000`), Backend (`port 5000`), Notification (`port 5001`).
- **Network Isolation**:
  - `frontend-backend` (`172.20.0.0/16`) connects Frontend and Backend.
  - `backend-notification` (`172.21.0.0/16`) connects Backend and Notification.
  - Frontend is completely isolated from Notification.
- **Storage Strategies**:
  - **Docker Named Volumes**: `backend-logs` and `notification-logs` mounted to `/app/logs`.
  - **Host Bind Mount**: `./backend-data` mounted to `/app/data` persisting `messages.json`.
- **Key Commands**:
  ```bash
  cd Lab-7-Multi-Network-Microservices
  # Automated script
  bash run-lab7.sh
  # Test message flow
  curl -s -L -X POST http://localhost:8080/send -d "message=Hello iVolve"
  curl -s http://localhost:8080/
  ```

---

## 📦 Lab 8: Containerized Node.js and MySQL Stack Using Docker Compose

👉 **Guide**: [`Lab-8-Docker-Compose-Node-MySQL/README.md`](Lab-8-Docker-Compose-Node-MySQL/README.md) | **Docker Hub**: [zeyadmvtr/ivolve-app](https://hub.docker.com/r/zeyadmvtr/ivolve-app)

- **Stack**: Node.js 18 Express web app + MySQL 8.0 database.
- **Docker Compose Features**:
  - Automatic `ivolve` database provisioning and root credentials.
  - Health checks (`mysqladmin ping`) to guarantee database readiness before web app starts.
  - Custom bridge network `ivolve-net` for private container networking.
  - Persistent named volume `db_data` for `/var/lib/mysql`.
  - Persistent named volume `app_logs` for `/app/logs` (Morgan HTTP access logs).
- **Docker Hub Deployment**:
  - Image built, tagged, and published to Docker Hub: `zeyadmvtr/ivolve-app:latest` and `zeyadmvtr/ivolve-app:v1.0`.
- **Key Commands**:
  ```bash
  cd Lab-8-Docker-Compose-Node-MySQL
  # Start the entire stack
  docker compose up --build -d
  # Verify health and readiness
  curl http://localhost:3000/health
  curl http://localhost:3000/ready
  # Tag and push image
  docker push zeyadmvtr/ivolve-app:latest
  ```

---

## ☸️ Lab 9: Deploy Kubernetes Cluster using Kubeadm

👉 **Guide**: [`Lab-9-Kubernetes-Kubeadm-Cluster/README.md`](Lab-9-Kubernetes-Kubeadm-Cluster/README.md)

- **Cluster Architecture**: Control Plane + Worker Nodes provisioned with `containerd` container runtime, `kubeadm`, `kubelet`, and `kubectl`.
- **Key Milestones**:
  1. **Container Runtime Configuration**:
     - Swap disabled (`swapoff -a`), kernel modules `overlay` and `br_netfilter` loaded.
     - Sysctl parameters configured (`net.bridge.bridge-nf-call-iptables = 1`, `net.ipv4.ip_forward = 1`).
     - `containerd` configured with `SystemdCgroup = true`.
  2. **Kubernetes v1.31 Setup**:
     - Repository configured via official community registry `pkgs.k8s.io`.
     - Packages installed and held (`apt-mark hold kubelet kubeadm kubectl`).
  3. **Control Plane Initialization & Kubectl Config**:
     - Initialized with `kubeadm init --pod-network-cidr=192.168.0.0/16`.
     - Configured `$HOME/.kube/config` with admin credentials.
  4. **Pod Networking with Calico CNI**:
     - Deployed Tigera Operator & Custom Resources configuring Pod CIDR `192.168.0.0/16`.
  5. **Worker Node Join & Verification**:
     - Joined worker nodes using discovery token and SHA-256 cert hash.
     - Verified all nodes in `Ready` state and core control plane pods running.
- **Key Commands**:
  ```bash
  cd Lab-9-Kubernetes-Kubeadm-Cluster
  # 1. Install Containerd & Kubeadm on all nodes
  sudo bash scripts/01-install-containerd.sh
  sudo bash scripts/02-install-kubeadm.sh
  # 2. Initialize Control Plane (Master only)
  sudo bash scripts/03-init-control-plane.sh
  # 3. Deploy Calico CNI
  bash scripts/04-install-calico.sh
  # 4. Join Worker Nodes
  sudo bash scripts/05-join-worker.sh <MASTER_IP:6443> <TOKEN> <CA_HASH>
  # 5. Verify Cluster Status
  bash scripts/06-verify-cluster.sh
  ```

---

## 🎯 Lab 10: Node Isolation Using Taints and Labels in Kubernetes

👉 **Guide**: [`Lab-10-Kubernetes-Taints-and-Labels/README.md`](Lab-10-Kubernetes-Taints-and-Labels/README.md)

- **Isolation Concept**: Complete mutual node dedication combining **Taints** (repelling uninvited pods) with **Node Labels & Selectors** (attracting targeted project pods).
- **Configuration**:
  - **Node Taint**: `workload=ivolveApp:NoSchedule` (blocks untolerated pods).
  - **Node Label**: `project=ivolve` (identifies worker for targeted scheduling).
- **Validation Scenarios**:
  1. **Untolerated Pod**: Automatically repelled and scheduled away from the tainted node.
  2. **Tolerated Pod**: Successfully scheduled on the tainted node.
  3. **Targeted iVolve App**: Combines `toleration` and `nodeSelector: project: ivolve` to achieve 100% dedicated node isolation.
- **Key Commands**:
  ```bash
  cd Lab-10-Kubernetes-Taints-and-Labels
  # 1. Apply taint and label to worker node
  kubectl taint nodes <worker-node> workload=ivolveApp:NoSchedule
  kubectl label nodes <worker-node> project=ivolve

  # 2. Verify taint and label
  kubectl describe node <worker-node> | grep -E "Labels:|Taints:" -A 3
  kubectl get nodes --show-labels

  # 3. Test isolation with automated script
  bash scripts/02-test-isolation.sh

  # 4. Remove taint and label (cleanup)
  kubectl taint nodes <worker-node> workload=ivolveApp:NoSchedule-
  kubectl label nodes <worker-node> project-
  ```

---

## 🛡️ Lab 11: Namespace Management and Resource Quota Enforcement

👉 **Guide**: [`Lab-11-Kubernetes-Namespace-and-ResourceQuota/README.md`](Lab-11-Kubernetes-Namespace-and-ResourceQuota/README.md)

- **Multi-Tenancy & Quota Concept**: Establishing isolated namespace boundaries and limiting aggregate resource consumption to prevent runaway workloads.
- **Configuration**:
  - **Namespace**: `ivolve` (logical isolation of project resources).
  - **ResourceQuota**: `ivolveQuota` enforcing `hard: pods: "3"`.
- **Validation Scenarios**:
  1. **Quota Allocation**: Deploys up to 3 pod replicas within quota capacity.
  2. **Admission Rejection**: Confirms that Kubernetes API and admission controllers reject 4th pod creation (`forbidden: exceeded quota: ivolveQuota`).
  3. **Controller Throttling**: Verifies ReplicaSet failure events when attempting to scale beyond the quota limit.
- **Key Commands**:
  ```bash
  cd Lab-11-Kubernetes-Namespace-and-ResourceQuota
  # 1. Create namespace and apply resource quota
  kubectl apply -f manifests/01-namespace.yaml
  kubectl apply -f manifests/02-resource-quota.yaml

  # 2. Inspect quota usage
  kubectl describe resourcequota ivolveQuota -n ivolve

  # 3. Test quota enforcement (automated script)
  bash scripts/02-verify-quota.sh
  ```

---

## 🔐 Lab 12: Managing Configuration and Sensitive Data with ConfigMaps and Secrets

👉 **Guide**: [`Lab-12-Kubernetes-ConfigMaps-and-Secrets/README.md`](Lab-12-Kubernetes-ConfigMaps-and-Secrets/README.md)

- **Configuration Decoupling**: Externalizing non-sensitive environment variables and credentials to adhere to 12-Factor App design and prevent credential leakage.
- **Configuration**:
  - **ConfigMap (`ivolveCM`)**: Stores `DB_HOST` (`ivolveDBSvc`) and `DB_USER` (`ivolveuser`).
  - **Secret (`ivolveSecret`)**: Stores Base64-encoded `MYSQL_ROOT_PASSWORD` and `DB_PASSWORD`.
- **Validation Scenarios**:
  1. **Base64 Encoding**: Encodes raw secrets for YAML manifest definition (`echo -n "..." | base64`).
  2. **Container Injection**: Injects variables via `valueFrom` (`configMapKeyRef` and `secretKeyRef`) into application pods.
  3. **Runtime Verification**: Inspects container environment variables to verify accurate decryption and values.
- **Key Commands**:
  ```bash
  cd Lab-12-Kubernetes-ConfigMaps-and-Secrets
  # 1. Apply ConfigMap and Secret
  kubectl apply -f manifests/01-configmap.yaml
  kubectl apply -f manifests/02-secret.yaml

  # 2. Verify creation and masked data
  kubectl describe configmap ivolveCM -n ivolve
  kubectl describe secret ivolveSecret -n ivolve

  # 3. Verify injection inside consumer pod
  bash scripts/02-verify-injection.sh
  ```

---

## 💾 Lab 13: Persistent Storage Setup for Application Logging

👉 **Guide**: [`Lab-13-Kubernetes-Persistent-Storage/README.md`](Lab-13-Kubernetes-Persistent-Storage/README.md)

- **Persistent Volume Architecture**: Setting up durable storage independent of pod lifecycles with multi-pod read/write capabilities (`ReadWriteMany`).
- **Configuration**:
  - **PersistentVolume (`ivolvePV`)**: 1Gi capacity, `hostPath: /mnt/app-logs`, `accessModes: [ReadWriteMany]`, `persistentVolumeReclaimPolicy: Retain`, `storageClassName: ""`.
  - **PersistentVolumeClaim (`ivolvePVC`)**: Requests 1Gi in namespace `ivolve` with matching `ReadWriteMany` mode.
- **Validation Scenarios**:
  1. **Volume Binding**: Verifies successful 1:1 binding between `ivolvePV` and `ivolvePVC`.
  2. **Concurrent Multi-Replica Logging**: Runs 2 replicas writing heartbeat logs concurrently to `/mnt/app-logs/application.log`.
  3. **Data Retention**: Deletes the deployment and attaches a new pod to confirm historical logs are preserved on the host.
- **Key Commands**:
  ```bash
  cd Lab-13-Kubernetes-Persistent-Storage
  # 1. Prepare hostPath directory on worker node
  sudo mkdir -p /mnt/app-logs && sudo chmod 777 /mnt/app-logs

  # 2. Apply PV and PVC
  kubectl apply -f manifests/01-persistent-volume.yaml
  kubectl apply -f manifests/02-persistent-volume-claim.yaml

  # 3. Check binding status
  kubectl get pv ivolvePV
  kubectl get pvc ivolvePVC -n ivolve

  # 4. Test concurrent logging and persistence
  bash scripts/03-verify-logging-persistence.sh
  ```

---

## 🗄️ Lab 14: StatefulSet with Headless Service

👉 **Guide**: [`Lab-14-Kubernetes-StatefulSet-and-Headless-Service/README.md`](Lab-14-Kubernetes-StatefulSet-and-Headless-Service/README.md)

- **Stateful Orchestration**: Deploying a persistent database (MySQL 8.0) leveraging **StatefulSets**, **Headless Services**, dedicated node placement, and dynamic volume claim templates.
- **Configuration**:
  - **StatefulSet (`ivolveDB`)**: 1 replica running MySQL 8.0 in namespace `ivolve`.
  - **Dedicated Placement**: `nodeSelector: project: ivolve` and `toleration: workload=ivolveApp:NoSchedule` (Lab 10).
  - **Decoupled Config**: Environment variables injected from `ivolveCM` and `ivolveSecret` (Lab 12).
  - **Storage Template**: `volumeClaimTemplates` mounting `/var/lib/mysql`.
  - **Headless Service (`ivolveDBSvc`)**: `clusterIP: None` targeting port 3306 for direct pod IP routing without proxy hops.
- **Validation Scenarios**:
  1. **Database Operations**: Connects via MySQL client, verifies table creation and record insertion.
  2. **CoreDNS Service Resolution**: Queries `ivolveDBSvc` to verify direct resolution to the underlying Pod IP.
  3. **Predictable Pod FQDN**: Resolves `ivolveDB-0.ivolveDBSvc.ivolve.svc.cluster.local`.
- **Key Commands**:
  ```bash
  cd Lab-14-Kubernetes-StatefulSet-and-Headless-Service
  # 1. Deploy Headless Service and StatefulSet
  bash scripts/01-deploy-statefulset.sh

  # 2. Verify MySQL operational status and client queries
  bash scripts/02-verify-database-connection.sh

  # 3. Verify DNS resolution inside cluster
  bash scripts/03-verify-dns-resolution.sh
  ```

---

## 👥 Author & Repository
- Repository: [https://github.com/zeyadmvtr/Ivolve](https://github.com/zeyadmvtr/Ivolve)
- Docker Hub: [https://hub.docker.com/u/zeyadmvtr](https://hub.docker.com/u/zeyadmvtr)
