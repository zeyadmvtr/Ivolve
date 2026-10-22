# Lab 4: Docker Image Optimization and Export/Load

This lab covers multi-stage Docker builds, security hardening via non-root users, size optimization, and Docker image archiving (`save` / `load`).

---

## 📋 Objectives

1. Clone application code and build an unoptimized image (`image1`) using the original Dockerfile.
2. Note image size and run `container1` to verify application functionality.
3. Write an optimized **multi-stage Dockerfile** running as a **non-root user**.
4. Build the optimized image as `image2` and compare its size against `image1`.
5. Run `container2` and verify both HTTP response and non-root user execution.
6. Export `image2` as a TAR archive named `lab-image.tar`.
7. Delete `image2` from the local Docker host.
8. Restore the image from `lab-image.tar` and verify restoration.

---

## 🗂️ Project Structure

```
Lab-4-Docker-Optimization/
├── Dockerfile                  # Multi-stage optimized Dockerfile (image2)
├── Dockerfile.original         # Original single-stage Dockerfile (image1)
├── pom.xml                     # Maven project descriptor
├── README.md                   # Lab guide
└── src/
    └── main/java/com/example/demo/
        └── DemoApplication.java # Spring Boot Web application
```

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Build Image from Existing Dockerfile (`image1`)

```bash
docker build -f Dockerfile.original -t image1 .
```

### Step 2: Note Image Size & Run `container1`

Check the image size:
```bash
docker images image1
```
> **Observed Size (`image1`):** ~430 MB (contains complete Maven distribution, JDK, build caches, and source files).

Run the container:
```bash
docker run -d --name container1 -p 8080:8080 image1
```

### Step 3: Verify Application & Clean Up `container1`

Verify HTTP response:
```bash
curl http://localhost:8080
```
**Expected Output:**
```
Hello from Dockerized Spring Boot!
```

Stop and delete `container1`:
```bash
docker stop container1
docker rm container1
```

---

### Step 4 & 5: Build Optimized Multi-Stage Image (`image2`)

The optimized [`Dockerfile`](Dockerfile) uses a two-stage build:
- **Stage 1 (Builder):** Uses `maven:3.9.15-eclipse-temurin-17-alpine` to compile and package `demo-0.0.1-SNAPSHOT.jar`.
- **Stage 2 (Runtime):** Uses lightweight `eclipse-temurin:17-jre-alpine`, creates a dedicated non-root user `appuser`, and copies only the JAR.

Build the optimized image:
```bash
docker build -t image2 .
```

Compare image sizes:
```bash
docker images image1 image2
```

#### 📊 Size Comparison Matrix

| Image | Base Image | Size | Size Reduction | Non-Root User |
| :--- | :--- | :--- | :--- | :--- |
| **`image1`** (Original) | `maven:3.9.15-eclipse-temurin-17-alpine` | **~430 MB** | Baseline | ❌ Root (`root`) |
| **`image2`** (Optimized) | `eclipse-temurin:17-jre-alpine` | **~185 MB** | **~57% smaller** | ✅ Non-Root (`appuser`) |

---

### Step 6: Run `container2` & Verify Non-Root User

Run the optimized container:
```bash
docker run -d --name container2 -p 8080:8080 image2
```

1. **Verify HTTP Endpoint:**
   ```bash
   curl http://localhost:8080
   ```
   **Output:** `Hello from Dockerized Spring Boot!`

2. **Verify Non-Root Execution:**
   ```bash
   docker exec container2 whoami
   ```
   **Expected Output:** `appuser`

   ```bash
   docker exec container2 id
   ```
   **Expected Output:** `uid=100(appuser) gid=101(appgroup) groups=101(appgroup)`

Stop and delete `container2`:
```bash
docker stop container2
docker rm container2
```

---

### Step 7, 8, 9 & 10: Docker Image Export & Restore

#### 1. Save Image to TAR Archive:
```bash
docker save -o lab-image.tar image2
```

Verify archive creation:
```bash
ls -lh lab-image.tar
```

#### 2. Delete Local Image:
```bash
docker rmi image2
```

Verify deletion from local host:
```bash
docker images image2
```
*(Should return empty / no images found)*

#### 3. Load Image from Archive:
```bash
docker load -i lab-image.tar
```
**Expected Output:**
```
Loaded image: image2:latest
```

#### 4. Verify Image is Restored:
```bash
docker images image2
```
