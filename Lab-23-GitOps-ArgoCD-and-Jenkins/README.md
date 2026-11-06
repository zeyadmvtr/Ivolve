# Lab 23: Implementing a GitOps Workflow with Jenkins and Argo CD

[![GitOps](https://img.shields.io/badge/GitOps-Declarative_Continuous_Delivery-4361EE.svg)](https://opengitops.net/)
[![Argo CD](https://img.shields.io/badge/Argo_CD-v2.12-EF7B45.svg?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI_Automation-D24939.svg?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Auto--Sync-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)

This lab demonstrates how to implement a modern **GitOps Continuous Delivery** workflow connecting **Jenkins CI** (for building, testing, scanning, and updating Git manifests) with **Argo CD** (for automated declarative cluster synchronization, drift detection, and self-healing).

---

## 🎯 Lab Objectives

- [x] **Install Argo CD** in the Kubernetes cluster inside the `argocd` namespace.
- [x] **Access the Argo CD Web UI** and authenticate using the auto-generated administrator secret (`argocd-initial-admin-secret`).
- [x] **Connect Argo CD to the GitHub repository**: [`https://github.com/zeyadmvtr/Ivolve.git`](https://github.com/zeyadmvtr/Ivolve.git).
- [x] **Create an Argo CD Application named `ivolve`**:
  - Point to Git repository URL and directory `Lab-23-GitOps-ArgoCD-and-Jenkins/manifests/app`.
  - Target cluster: `https://kubernetes.default.svc` in namespace `ivolve`.
- [x] **Configure Automated Synchronization**:
  - Enable `automated` sync policy with **`prune: true`** and **`selfHeal: true`**.
- [x] **Modify `DeployOnK8s` Shared Library**:
  - Transition from direct cluster `kubectl apply` to the **GitOps paradigm**: update `deployment.yaml` and **push the commit back to GitHub**.
- [x] **Trigger End-to-End Pipeline**:
  - Publish a new container image and push the updated manifest to GitHub.
- [x] **Confirm Argo CD Detection & Synchronization**:
  - Verify that Argo CD automatically reconciles cluster state with Git commits.

---

## 💡 GitOps Continuous Delivery Architecture

```
                                      +---------------------------------------------+
                                      |             DEVELOPER COMMIT                |
                                      +---------------------------------------------+
                                                             |
                                                             v
+---------------------------------------------------------------------------------------------------+
|                                       CI TIER: JENKINS PIPELINE                                   |
|                                                                                                   |
|  1. Build Application (mvn package)                                                               |
|  2. Build & Scan Container Image (docker build + trivy)                                           |
|  3. Push Image to Docker Hub (zeyadmvtr/demoapp:vXX)                                               |
|  4. DeployOnK8s GitOps:                                                                           |
|     - Updates image tag in manifests/app/deployment.yaml                                          |
|     - Executes 'git commit' and 'git push' to GitHub                                              |
+---------------------------------------------------------------------------------------------------+
                                                             |
                                                Pushes commit| to 'main'
                                                             v
+---------------------------------------------------------------------------------------------------+
|                           SINGLE SOURCE OF TRUTH: GITHUB REPOSITORY                               |
|                                 https://github.com/zeyadmvtr/Ivolve.git                           |
|                         (Manifest Directory: manifests/app/deployment.yaml)                       |
+---------------------------------------------------------------------------------------------------+
                                                             |
                                         Watches for commits | (Auto-Sync Interval / Webhook)
                                                             v
+---------------------------------------------------------------------------------------------------+
|                                       CD TIER: ARGO CD OPERATOR                                   |
|                                                                                                   |
|  - Compares desired state in Git vs live state in Kubernetes                                      |
|  - Detects OutOfSync revision                                                                     |
|  - Applies Automated Synchronization:                                                             |
|      * Automated Prune: cleans deleted objects                                                    |
|      * Automated Self-Heal: reverts manual drift                                                  |
+---------------------------------------------------------------------------------------------------+
                                                             |
                                           Reconciles cluster| state
                                                             v
+---------------------------------------------------------------------------------------------------+
|                                      KUBERNETES 'ivolve' NAMESPACE                                |
|                                                                                                   |
|  [ Pod: ivolve-gitops-app-1 ] <--- Running new image: zeyadmvtr/demoapp:vXX                        |
|  [ Pod: ivolve-gitops-app-2 ] <--- Running new image: zeyadmvtr/demoapp:vXX                        |
+---------------------------------------------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-23-GitOps-ArgoCD-and-Jenkins/
├── manifests/
│   ├── 02-argocd-repo-secret.yaml               # Repository credentials connection
│   ├── 03-argocd-application-ivolve.yaml        # Argo CD Application resource with auto-sync
│   └── app/
│       ├── deployment.yaml                      # App deployment tracked by Argo CD
│       └── service.yaml                         # App service tracked by Argo CD
├── shared-library/
│   └── vars/
│       └── deployOnK8s.groovy                   # GitOps step: commits & pushes to GitHub
├── scripts/
│   ├── 01-install-argocd.sh                     # Installs Argo CD and configures NodePort
│   ├── 02-access-argocd-ui.sh                   # Extracts admin password & UI URL
│   ├── 03-create-argocd-app.sh                  # Connects repo & creates 'ivolve' application
│   ├── 04-verify-gitops-sync.sh                 # Validates sync status & live pod images
│   └── 05-cleanup.sh                            # Teardown script
├── Jenkinsfile                                  # GitOps CI pipeline triggering Git push
└── README.md                                    # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Install Argo CD & Access the Web UI

Run the automated installer:

```bash
bash scripts/01-install-argocd.sh
```

Retrieve the administrator credentials:

```bash
bash scripts/02-access-argocd-ui.sh
```

**Output:**
```
==========================================================
>>> Argo CD UI Login Credentials
==========================================================
Web URL   : https://192.168.0.10:30443 (or https://localhost:8080)
Username  : admin
Password  : b7a92FqR8...
==========================================================
```

Log in to the Argo CD dashboard in your browser.

---

### Step 2: Create Argo CD Application `ivolve`

Apply the declarative Application manifest:

```bash
kubectl apply -f manifests/03-argocd-application-ivolve.yaml
```

**Manifest Highlights (`manifests/03-argocd-application-ivolve.yaml`):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ivolve
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/zeyadmvtr/Ivolve.git
    targetRevision: main
    path: Lab-23-GitOps-ArgoCD-and-Jenkins/manifests/app
  destination:
    server: https://kubernetes.default.svc
    namespace: ivolve
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Verify application registration:
```bash
kubectl get application ivolve -n argocd
```

**Output:**
```
NAME     SYNC STATUS   HEALTH STATUS
ivolve   Synced        Healthy
```

---

### Step 3: GitOps Jenkins Shared Library (`deployOnK8s.groovy`)

In a GitOps pipeline, CI **never directly touches the Kubernetes API**. Instead, it commits the desired state to Git:

```groovy
def call(Map config = [:]) {
    String manifestPath = config.manifestPath
    String fullImage    = config.fullImage
    String gitBranch    = config.gitBranch ?: 'main'

    stage('Edit Deployment File') {
        sh "sed -i.bak -E 's|image: .*/demoapp:.*|image: ${fullImage}|g' ${manifestPath}"
    }

    stage('Push Updates to GitHub (GitOps Trigger)') {
        withCredentials([usernamePassword(credentialsId: 'github-pat-credentials', usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
            sh """
                git config user.name "jenkins-bot"
                git config user.email "jenkins-bot@ivolve.local"
                git add ${manifestPath}
                git commit -m "ci(gitops): update application image to ${fullImage} [skip ci]"
                git push https://\${TOKEN}@github.com/zeyadmvtr/Ivolve.git HEAD:${gitBranch}
            """
        }
    }
}
```

---

### Step 4: Confirm Argo CD Detects Changes & Synchronizes Cluster

Once Jenkins pushes the commit to GitHub, Argo CD's reconciliation loop detects that the cluster state has diverged from Git:

```bash
bash scripts/04-verify-gitops-sync.sh
```

**Output:**
```
==========================================================
>>> Step 1: Inspecting Argo CD Application Sync & Health Status
==========================================================
Sync Status   : Synced
Health Status : Healthy
Git Revision  : a8e29bf42...

==========================================================
>>> Step 2: Inspecting Deployed Kubernetes Workload in 'ivolve' Namespace
==========================================================
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
ivolve-gitops-app   2/2     2            2           1m

Active Container Image deployed by Argo CD: zeyadmvtr/demoapp:v2
==========================================================
>>> [SUCCESS] GitOps synchronization confirmed!
==========================================================
```

---

## ⚡ Automated Execution

```bash
# 1. Install Argo CD
bash scripts/01-install-argocd.sh

# 2. Retrieve UI Login Coordinates
bash scripts/02-access-argocd-ui.sh

# 3. Create 'ivolve' Argo CD Application
bash scripts/03-create-argocd-app.sh

# 4. Verify GitOps Sync & Active Pod Images
bash scripts/04-verify-gitops-sync.sh

# 5. Teardown
bash scripts/05-cleanup.sh
```
