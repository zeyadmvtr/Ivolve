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

## 👥 Author & Repository
- Repository: [https://github.com/zeyadmvtr/Ivolve](https://github.com/zeyadmvtr/Ivolve)
- Docker Hub: [https://hub.docker.com/u/zeyadmvtr](https://hub.docker.com/u/zeyadmvtr)
