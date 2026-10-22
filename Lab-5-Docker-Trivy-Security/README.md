# Lab 5: Docker Image Vulnerability Scanning with Trivy

This lab focuses on container security auditing using **Aqua Security's Trivy**, scanning for vulnerabilities (CVEs), generating HTML security reports, and remediating identified HIGH and CRITICAL vulnerabilities.

---

## 📋 Objectives

1. Clone application and Dockerfile from repository.
2. Build Docker image from provided Dockerfile and tag as `trivy-lab:v1`.
3. Install Trivy and verify installation.
4. Scan `trivy-lab:v1` for vulnerabilities and review findings.
5. Filter scan results to display only **HIGH** and **CRITICAL** vulnerabilities.
6. Generate an **HTML vulnerability report**.
7. **Bonus - Vulnerability Remediation**:
   - Investigate detected HIGH and CRITICAL vulnerabilities.
   - Remediate issues by updating base image and application dependencies.
   - Rebuild image tagged as `ivolve-app:v2`.
   - Rescan with Trivy, generate updated HTML report, and verify that zero HIGH/CRITICAL vulnerabilities remain.

---

## 🗂️ Project Structure

```
Lab-5-Docker-Trivy-Security/
├── Dockerfile.v1               # Original vulnerable Dockerfile (node:18-bullseye)
├── Dockerfile.v2               # Remediated secure Dockerfile (node:20-alpine)
├── REMEDIATION.md              # In-depth vulnerability & CVE remediation analysis
├── README.md                   # Lab guide
├── app.js                      # Express.js web server
├── package.json                # Dependencies
├── v1-vulnerable/              # Standalone workspace for v1
│   ├── Dockerfile
│   ├── app.js
│   └── package.json
└── v2-remediated/              # Standalone workspace for v2 (hardened)
    ├── Dockerfile
    ├── app.js
    └── package.json
```

---

## ⚙️ Prerequisites: Installing Trivy

Choose the installation method for your environment:

### Method A: Run Trivy via Docker (No local installation needed)
```bash
# Verify Trivy version
docker run --rm aquasec/trivy:latest --version
```

### Method B: Install on Windows
```powershell
# Using Winget
winget install AquaSecurity.Trivy

# Or using Chocolatey
choco install trivy
```

### Method C: Install on Linux (Ubuntu/Debian)
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy
```

Verify installation:
```bash
trivy --version
```

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Build Initial Image (`trivy-lab:v1`)

```bash
docker build -f Dockerfile.v1 -t trivy-lab:v1 .
```
*(Or inside `v1-vulnerable/`: `cd v1-vulnerable && docker build -t trivy-lab:v1 .`)*

---

### Step 2: Scan Image for Vulnerabilities

Run a full vulnerability scan:
```bash
trivy image trivy-lab:v1
```
*(If using Docker-based Trivy:)*
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image trivy-lab:v1
```

---

### Step 3: Filter for HIGH and CRITICAL Vulnerabilities

Filter out LOW and MEDIUM severities to focus on actionable risks:
```bash
trivy image --severity HIGH,CRITICAL trivy-lab:v1
```

---

### Step 4: Generate HTML Vulnerability Report

Generate a standalone HTML security audit report:

```bash
trivy image --format template --template "@contrib/html.tpl" -o report-v1.html trivy-lab:v1
```
*(On modern Trivy versions supporting native HTML output:)*
```bash
trivy image --format html -o report-v1.html trivy-lab:v1
```

Open `report-v1.html` in your browser to inspect the detailed CVE breakdowns, CVSS scores, affected packages, and available patches.

---

## 🏆 Bonus: Vulnerability Remediation (`ivolve-app:v2`)

As analyzed in [REMEDIATION.md](REMEDIATION.md), vulnerabilities in `v1` stem from:
1. `node:18-bullseye` containing dozens of OS-level CVEs.
2. `express: 4.18.2` sub-dependencies (`path-to-regexp`, `cookie`).

### Step 5: Build Remediated Image (`ivolve-app:v2`)

The updated [`Dockerfile.v2`](Dockerfile.v2) and [`v2-remediated/`](v2-remediated/) folder upgrade to `node:20-alpine` and `express: ^4.21.2` running under non-root `USER node`:

```bash
docker build -f Dockerfile.v2 -t ivolve-app:v2 .
```
*(Or inside `v2-remediated/`: `cd v2-remediated && docker build -t ivolve-app:v2 .`)*

---

### Step 6: Rescan Remediated Image & Verify Fixes

Run the severity check on `ivolve-app:v2`:
```bash
trivy image --severity HIGH,CRITICAL ivolve-app:v2
```

Generate the remediation verification HTML report:
```bash
trivy image --format template --template "@contrib/html.tpl" -o report-v2.html ivolve-app:v2
```

**Expected Result:**
```
ivolve-app:v2 (alpine 3.20.x)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)
```
Zero HIGH and zero CRITICAL vulnerabilities remain!
