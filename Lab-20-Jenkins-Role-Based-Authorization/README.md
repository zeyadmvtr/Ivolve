# Lab 20: Role-Based Authorization in Jenkins

[![Jenkins](https://img.shields.io/badge/Jenkins-LTS-D24939.svg?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Security](https://img.shields.io/badge/Plugin-Role--Based_Strategy-blue.svg)](https://plugins.jenkins.io/role-strategy/)
[![JCasC](https://img.shields.io/badge/Config-Jenkins_as_Code-brightgreen.svg)](https://plugins.jenkins.io/configuration-as-code/)

This lab demonstrates how to implement fine-grained **Role-Based Access Control (RBAC)** in Jenkins using the **Role-Based Authorization Strategy** plugin, creating distinct users (`user1` and `user2`) and assigning dedicated roles (**admin** and **read-only**).

---

## 🎯 Lab Objectives

- [x] **Create users in Jenkins**:
  - `user1` (Designated Administrator)
  - `user2` (Designated Read-Only Auditor / Developer)
- [x] **Configure Role-Based Authorization Strategy**:
  - Install and enable `role-strategy` plugin.
  - Define Global Role `admin` with full permissions (`Overall/Administer`).
  - Define Global Role `read-only` with view-only permissions (`Overall/Read`, `Job/Read`, `View/Read`).
- [x] **Assign Roles**:
  - Assign role **admin** to `user1`.
  - Assign role **read-only** to `user2`.
- [x] **Validate Access Controls**:
  - Verify `user1` can access `/manage`, create pipelines, and administer Jenkins (HTTP 200).
  - Verify `user2` can view dashboards and read job status (HTTP 200), but is rejected with **HTTP 403 Forbidden** on administrative endpoints.

---

## 💡 Permissions & Authorization Matrix

| Capability | Permission Flag | `user1` (admin) | `user2` (read-only) |
| :--- | :--- | :---: | :---: |
| **Login & View Dashboard** | `Overall/Read` | ✅ **Allowed** | ✅ **Allowed** |
| **View Job Status & Logs** | `Job/Read` | ✅ **Allowed** | ✅ **Allowed** |
| **View Job Folders & Views**| `View/Read` | ✅ **Allowed** | ✅ **Allowed** |
| **Create / Edit / Build Jobs**| `Job/Create`, `Job/Build` | ✅ **Allowed** | ❌ **Denied** |
| **Manage Jenkins & Plugins** | `Overall/Administer` | ✅ **Allowed** | ❌ **Denied (HTTP 403)** |
| **Manage Credentials & Nodes**| `Credentials/*`, `Agent/*` | ✅ **Allowed** | ❌ **Denied (HTTP 403)** |

---

## 📁 Directory Structure

```
Lab-20-Jenkins-Role-Based-Authorization/
├── configs/
│   ├── jenkins.yaml                     # JCasC declarative configuration
│   └── plugins.txt                      # Plugin dependency list (role-strategy, etc.)
├── init.groovy.d/
│   └── 01-role-strategy.groovy          # Automated Groovy initialization script
├── scripts/
│   ├── 01-start-jenkins.sh              # Launches Jenkins with Docker Compose
│   ├── 02-verify-roles.sh               # Validates API permissions (200 vs 403)
│   └── 03-cleanup.sh                    # Teardown script
├── docker-compose.yml                   # Containerized Jenkins environment
└── README.md                            # Comprehensive documentation & UI walkthrough
```

---

## 🚀 Step-by-Step Implementation Guide

### Method 1: Web UI Configuration (Manual Walkthrough)

#### Step 1: Install Plugin
1. Go to **Dashboard** -> **Manage Jenkins** -> **Plugins**.
2. Under the **Available plugins** tab, search for `Role-based Authorization Strategy`.
3. Select it and click **Install without restart**.

#### Step 2: Enable Role-Based Authorization
1. Go to **Manage Jenkins** -> **Security**.
2. Under **Authentication**:
   - Ensure **Security Realm** is set to **Jenkins’ own user database**.
3. Under **Authorization**:
   - Select **Role-Based Strategy**.
4. Click **Save**.

#### Step 3: Create User Accounts
1. Go to **Manage Jenkins** -> **Users**.
2. Click **Create User**:
   - Username: `user1`, Password: `user1Pass2026!`, Full Name: `Admin User`
3. Click **Create User**:
   - Username: `user2`, Password: `user2Pass2026!`, Full Name: `Read-Only User`

#### Step 4: Manage Roles
1. Go to **Manage Jenkins** -> **Manage and Assign Roles** -> **Manage Roles**.
2. Under **Global roles**:
   - Create role `admin`: Check `Overall/Administer`.
   - Create role `read-only`: Check `Overall/Read`, `Job/Read`, `View/Read`.
3. Click **Save**.

#### Step 5: Assign Roles to Users
1. Go to **Manage Jenkins** -> **Manage and Assign Roles** -> **Assign Roles**.
2. Under **Global roles**:
   - Add user `user1` -> Check `admin`.
   - Add user `user2` -> Check `read-only`.
3. Click **Save**.

---

### Method 2: Infrastructure as Code (JCasC & Groovy Automation)

Deploy the pre-configured container using Docker Compose:

```bash
bash scripts/01-start-jenkins.sh
```

**JCasC Definition (`configs/jenkins.yaml`):**
```yaml
jenkins:
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "user1"
          name: "Admin User"
          password: "user1Pass2026!"
        - id: "user2"
          name: "Read-Only User"
          password: "user2Pass2026!"

  authorizationStrategy:
    roleBased:
      roles:
        global:
          - name: "admin"
            permissions:
              - "Overall/Administer"
            entries:
              - user: "user1"
          - name: "read-only"
            permissions:
              - "Overall/Read"
              - "Job/Read"
              - "View/Read"
            entries:
              - user: "user2"
```

---

## ⚡ Automated Verification

Test role permissions against the live Jenkins controller:

```bash
bash scripts/02-verify-roles.sh
```

**Output:**
```
==========================================================
>>> Test 1: Testing user1 (Role: Admin)
==========================================================
HTTP response code for user1 accessing /manage : 200
[+] [CONFIRMED] user1 has administrative access (HTTP 200)!
HTTP response code for user1 accessing API     : 200

==========================================================
>>> Test 2: Testing user2 (Role: Read-Only)
==========================================================
HTTP response code for user2 accessing API     : 200
[+] [CONFIRMED] user2 has read access to view Jenkins jobs (HTTP 200)!
HTTP response code for user2 accessing /manage : 403
[+] [CONFIRMED] user2 is FORBIDDEN (HTTP 403) from administrative actions!

==========================================================
>>> [SUCCESS] Role-based authorization verified successfully!
==========================================================
```
