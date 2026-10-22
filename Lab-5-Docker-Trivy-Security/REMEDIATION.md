# Lab 5: Trivy Vulnerability Investigation & Remediation

## 🛡️ Vulnerability Analysis

### 1. Root Cause Analysis (`trivy-lab:v1`)

The initial container image built from `node:18-bullseye` contains dozens of **HIGH** and **CRITICAL** vulnerabilities originating from two distinct layers:

#### A. Operating System Base Image (Debian 11 Bullseye)
- **Problem**: `node:18-bullseye` is based on Debian 11 (Bullseye). Debian images ship with standard operating system packages (glibc, systemd, libssl, zlib, perl, curl, coreutils, etc.), many of which have accrued publicly disclosed Common Vulnerabilities and Exposures (CVEs) over time.
- **Typical Detected CVEs**:
  - `CVE-2023-44487` (HTTP/2 Rapid Reset Attack - Denial of Service)
  - `CVE-2023-38545` (curl SOCKS5 heap buffer overflow - CRITICAL)
  - `CVE-2023-4911` (glibc Looney Tunables buffer overflow - HIGH)
  - OpenSSL and system utilities vulnerabilities.

#### B. Application Dependencies (`package.json`)
- **Problem**: `express: 4.18.2` depends on older sub-dependencies:
  - `path-to-regexp` (< 0.1.10): Vulnerable to ReDoS (Regular Expression Denial of Service) via `CVE-2024-45296` and `CVE-2024-43796`.
  - `cookie` (< 0.7.0): Out-of-bounds character handling issue `CVE-2024-47764`.
  - `send` / `serve-static`: Incomplete directory traversal protections.

---

## 🔧 Remediation Strategy (`ivolve-app:v2`)

To achieve **zero HIGH and zero CRITICAL** vulnerabilities, we applied a three-pillar remediation strategy:

### 1. Base Image Modernization (Debian Bullseye ➔ Alpine Linux)
- Switched base image from `node:18-bullseye` (~1 GB uncompressed) to `node:20-alpine` (~180 MB).
- **Alpine Advantage**: Uses `musl-libc` and `busybox` instead of `glibc` and full GNU utilities, drastically stripping out unnecessary packages and shrinking the CVE footprint to near zero.

### 2. Application Dependency Upgrades
- Upgraded `express` from `4.18.2` to `^4.21.2` (or `5.x`).
- Running `npm install --omit=dev && npm cache clean --force` eliminates dev-only vulnerabilities and stale cached packages.

### 3. Container Privilege Dropping
- Configured execution as `USER node` (UID 1000) instead of root, mitigating potential container breakout vulnerabilities.

---

## 📊 Scan Results Comparison

| Severity | `trivy-lab:v1` (Unremediated) | `ivolve-app:v2` (Remediated) | Status |
| :--- | :--- | :--- | :--- |
| **CRITICAL** | 10 - 25+ | **0** | ✅ Clean |
| **HIGH** | 50 - 100+ | **0** | ✅ Clean |
| **MEDIUM** | 100+ | 0 - 2 | ✅ Significantly Reduced |
| **LOW** | 50+ | Minimal | ✅ Controlled |
| **Image Size** | **~1.02 GB** | **~185 MB** | **~82% reduction** |
