# Lab 19: Securing Kubernetes with RBAC and Service Accounts

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Security](https://img.shields.io/badge/Security-RBAC_%26_ServiceAccounts-critical.svg)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins_Integration-D24939.svg?logo=jenkins&logoColor=white)](https://www.jenkins.io/)

This lab demonstrates how to implement **Role-Based Access Control (RBAC)** and configure a dedicated, least-privileged **Service Account** (`jenkinsSA`) in Kubernetes for CI/CD automation pipelines.

---

## 🎯 Lab Objectives

- [x] **Create `jenkinsSA` Service Account** in the `ivolve` namespace.
- [x] **Create a token** for the service account (both ephemeral token via `kubectl create token` and persistent CI/CD token via a Secret).
- [x] **Define a Role named `ivolveDeployRole`** that grants create/update permissions strictly on `deployments` in the `ivolve` namespace.
- [x] **Create a RoleBinding named `ivolveDeployRoleBinding`** to bind `ivolveDeployRole` to `jenkinsSA`.
- [x] **Validate RBAC Enforcement**:
  - Verify that `jenkinsSA` can **only** create and update deployments in the `ivolve` namespace.
  - Verify that all unauthorized actions (deleting deployments, accessing pods/secrets, operating outside the `ivolve` namespace) are strictly denied by the Kubernetes API.

---

## 💡 Architecture & RBAC Security Model

```
+---------------------------------------------------------------------------------------------------+
|                                     KUBERNETES API SERVER                                         |
+---------------------------------------------------------------------------------------------------+
                                                  ^
                                                  | Authentication via Bearer Token
                                                  |
                         +--------------------------------------------------+
                         | ServiceAccount: jenkinsSA                        |
                         | (Namespace: ivolve)                              |
                         +--------------------------------------------------+
                                                  |
                                                  | Bound via
                                                  v
                         +--------------------------------------------------+
                         | RoleBinding: ivolveDeployRoleBinding             |
                         | (Namespace: ivolve)                              |
                         +--------------------------------------------------+
                                                  |
                                                  | Evaluates permissions in
                                                  v
                         +--------------------------------------------------+
                         | Role: ivolveDeployRole                           |
                         | (Namespace: ivolve)                              |
                         | - apiGroups: ["apps"]                            |
                         | - resources: ["deployments"]                     |
                         | - verbs: ["create", "update", "patch", "get"]    |
                         +--------------------------------------------------+
                                /                                    \
                               v                                      v
                 [ PERMITTED ACTIONS ]                       [ DENIED ACTIONS ]
                 - Create deployment in ivolve               - Delete deployment in ivolve (403)
                 - Update deployment in ivolve               - Read/write secrets in ivolve (403)
                 - Patch deployment in ivolve                - Any action in default/kube-system
```

---

## 📁 Directory Structure

```
Lab-19-Kubernetes-RBAC-ServiceAccounts/
├── manifests/
│   ├── 01-service-account.yaml                  # ServiceAccount 'jenkinsSA'
│   ├── 02-service-account-token.yaml            # Secret generating persistent token
│   ├── 03-role.yaml                             # Role 'ivolveDeployRole'
│   └── 04-rolebinding.yaml                      # RoleBinding 'ivolveDeployRoleBinding'
├── scripts/
│   ├── 01-setup-rbac.sh                         # Applies SA, Token, Role, and RoleBinding
│   ├── 02-generate-token-kubeconfig.sh          # Generates dedicated kubeconfig for Jenkins
│   ├── 03-validate-rbac-permissions.sh          # Comprehensive kubectl auth can-i test suite
│   └── 04-cleanup.sh                            # Teardown script
└── README.md                                    # Comprehensive documentation & walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Create ServiceAccount and Generate Token

Apply the ServiceAccount and Token manifests:

```bash
kubectl apply -f manifests/01-service-account.yaml
kubectl apply -f manifests/02-service-account-token.yaml
```

**Manifest (`manifests/01-service-account.yaml`):**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkinsSA
  namespace: ivolve
```

**Manifest (`manifests/02-service-account-token.yaml`):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-sa-token
  namespace: ivolve
  annotations:
    kubernetes.io/service-account.name: jenkinsSA
type: kubernetes.io/service-account-token
```

Extract the decoded token:
```bash
TOKEN=$(kubectl get secret jenkins-sa-token -n ivolve -o jsonpath='{.data.token}' | base64 --decode)
echo "${TOKEN:0:30}..."
```

---

### Step 2: Define Role `ivolveDeployRole`

Apply the role restricting permissions to deployments in `ivolve`:

```bash
kubectl apply -f manifests/03-role.yaml
```

**Manifest (`manifests/03-role.yaml`):**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ivolveDeployRole
  namespace: ivolve
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

---

### Step 3: Create RoleBinding `ivolveDeployRoleBinding`

Bind the role to `jenkinsSA`:

```bash
kubectl apply -f manifests/04-rolebinding.yaml
```

**Manifest (`manifests/04-rolebinding.yaml`):**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ivolveDeployRoleBinding
  namespace: ivolve
subjects:
  - kind: ServiceAccount
    name: jenkinsSA
    namespace: ivolve
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ivolveDeployRole
```

---

### Step 4: Validate RBAC Permissions (`kubectl auth can-i`)

Run permission checks impersonating `system:serviceaccount:ivolve:jenkinsSA`:

#### 1. Validating Allowed Operations (Deployments in `ivolve`):
```bash
# Can create deployments?
kubectl auth can-i create deployments -n ivolve --as=system:serviceaccount:ivolve:jenkinsSA
# Output: yes

# Can update deployments?
kubectl auth can-i update deployments -n ivolve --as=system:serviceaccount:ivolve:jenkinsSA
# Output: yes
```

#### 2. Validating Denied Operations (Least Privilege Enforcement):
```bash
# Can delete deployments?
kubectl auth can-i delete deployments -n ivolve --as=system:serviceaccount:ivolve:jenkinsSA
# Output: no

# Can read secrets?
kubectl auth can-i get secrets -n ivolve --as=system:serviceaccount:ivolve:jenkinsSA
# Output: no

# Can touch other namespaces (e.g. default)?
kubectl auth can-i create deployments -n default --as=system:serviceaccount:ivolve:jenkinsSA
# Output: no
```

---

## ⚡ Automated Execution

```bash
# 1. Setup RBAC (SA, Token, Role, RoleBinding)
bash scripts/01-setup-rbac.sh

# 2. Extract Token and Export Jenkins Kubeconfig
bash scripts/02-generate-token-kubeconfig.sh

# 3. Execute Permission Validation Suite
bash scripts/03-validate-rbac-permissions.sh

# 4. Teardown
bash scripts/04-cleanup.sh
```
