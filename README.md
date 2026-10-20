# iVolve DevOps & Build Tools Labs

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://www.oracle.com/java/)
[![Maven](https://img.shields.io/badge/Maven-3.8+-blue.svg)](https://maven.apache.org/)
[![Gradle](https://img.shields.io/badge/Gradle-8+-02303A.svg)](https://gradle.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED.svg)](https://www.docker.com/)

This repository contains the completed implementations, configurations, Dockerfiles, and documentation for the **iVolve** training labs:
- **Build Tools Overview** (Maven & Gradle)
- **Containerization with Docker** (Single-stage Build vs. Local Pre-build)

---

## 📚 Table of Contents

- [Repository Structure](#-repository-structure)
- [Lab 1: Java Application with Maven](#-lab-1-building-and-packaging-java-application-with-maven)
- [Lab 2: Application with Gradle](#-lab-2-building-and-packaging-application-with-gradle)
- [Lab 3: Docker Containerization for Java App](#-lab-3-creating-a-docker-image-for-a-java-application)
  - [Part 1: Build Inside Docker](#part-1-build-inside-docker-app1)
  - [Part 2: Build Locally](#part-2-build-locally-app2)
  - [Bonus: Image Comparison](#bonus-image-size-comparison--analysis)
- [Verification & Quick Start](#-quick-start--verification)

---

## 🗂️ Repository Structure

```
.
├── Lab-1-Maven/                           # Lab 1: Java application using Apache Maven
│   ├── pom.xml
│   ├── README.md
│   └── src/
│       ├── main/java/com/example/calculator/
│       └── test/java/com/example/calculator/
├── Lab-2-Gradle/                          # Lab 2: Java application using Gradle
│   ├── build.gradle
│   ├── settings.gradle
│   ├── README.md
│   └── src/
│       ├── main/java/com/example/calculator/
│       └── test/java/com/example/calculator/
├── Lab-3-Docker/                          # Lab 3: Containerization approaches & Dockerfiles
│   ├── Dockerfile.part1                   # Part 1: Maven build inside container
│   ├── Dockerfile.part2                   # Part 2: Lightweight JRE runtime
│   ├── COMPARISON.md                      # Detailed comparison report (sizes, layers, security)
│   ├── README.md                          # Lab 3 Guide
│   ├── pom.xml
│   ├── src/
│   ├── part1-build-inside-docker/         # Standalone workspace for Part 1
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   ├── src/
│   │   └── README.md
│   └── part2-build-locally/               # Standalone workspace for Part 2
│       ├── Dockerfile
│       ├── pom.xml
│       ├── src/
│       └── README.md
├── .gitignore
└── README.md
```

---

## 🛠️ Lab 1: Building and Packaging Java Application with Maven

Located in [`Lab-1-Maven/`](Lab-1-Maven/README.md).

### Key Steps:
1. **Prerequisites**: Java 17+ and Maven 3.8+ installed.
2. **Run Unit Tests**:
   ```bash
   cd Lab-1-Maven
   mvn test
   ```
3. **Build & Package**:
   ```bash
   mvn clean package
   ```
   Generates executable artifact at `target/calculator.jar`.
4. **Run & Verify**:
   ```bash
   java -jar target/calculator.jar
   ```

---

## 🐘 Lab 2: Building and Packaging Application with Gradle

Located in [`Lab-2-Gradle/`](Lab-2-Gradle/README.md).

*(Note: While the slide title references "Go", the exercise configures and builds the Java Calculator application with Gradle, generating `build/libs/calculator.jar`)*.

### Key Steps:
1. **Prerequisites**: Java 17+ and Gradle 7+ / 8+ installed.
2. **Run Unit Tests**:
   ```bash
   cd Lab-2-Gradle
   gradle test
   ```
3. **Build & Package**:
   ```bash
   gradle build
   ```
   Generates executable artifact at `build/libs/calculator.jar`.
4. **Run & Verify**:
   ```bash
   java -jar build/libs/calculator.jar
   ```

---

## 🐳 Lab 3: Creating a Docker Image for a Java Application

Located in [`Lab-3-Docker/`](Lab-3-Docker/README.md).

### Part 1: Build Inside Docker (`app1`)
- Base Image: `maven:3.9.6-eclipse-temurin-17`
- Uses a dedicated non-root user (`appuser`, UID 1001).
- Copies source code and runs `mvn clean package` inside Docker.
- Exposes port `8080` and sets entrypoint to `target/calculator.jar`.

```bash
cd Lab-3-Docker
# Build image
docker build -f Dockerfile.part1 -t app1 .

# Check size (~650 MB - 850 MB)
docker images app1

# Run and verify
docker run -it --name container1 -p 8080:8080 app1

# Cleanup
docker rm container1
docker rmi app1
```

---

### Part 2: Build Locally (`app2`)
- Pre-compiles the application on the host: `mvn clean package`.
- Base Image: `eclipse-temurin:17-jre` (lightweight JRE runtime).
- Uses a non-root user (`appuser`, UID 1001).
- Copies only `target/calculator.jar` into the container.
- Exposes port `8080`.

```bash
cd Lab-3-Docker
# 1. Compile on host
mvn clean package

# 2. Build image
docker build -f Dockerfile.part2 -t app2 .

# 3. Check size (~220 MB - 260 MB)
docker images app2

# 4. Run and verify
docker run -it --name container2 -p 8080:8080 app2

# 5. Cleanup
docker rm container2
docker rmi app2
```

---

### 📊 Bonus: Image Size Comparison & Analysis

| Aspect | Part 1 (`app1`) | Part 2 (`app2`) |
| :--- | :--- | :--- |
| **Base Image** | `maven:3.9.6-eclipse-temurin-17` | `eclipse-temurin:17-jre` |
| **Approximate Size** | **~650 MB - 850 MB** | **~220 MB - 260 MB** |
| **Build Location** | Inside container | Local host system |
| **Dependencies on Host** | Docker only | Docker + Maven + JDK 17 |
| **Security Surface** | Larger (includes JDK, Maven, compilers) | Minimal (JRE only, no build tools) |
| **Best Used For** | Standalone CI runners without JDK | Fast production deployments |

👉 For an in-depth breakdown of layer differences, attack surface, and multi-stage build best practices, read [Lab-3-Docker/COMPARISON.md](Lab-3-Docker/COMPARISON.md).

---

## 👥 Author & Repository
- Repository: [https://github.com/zeyadmvtr/Ivolve](https://github.com/zeyadmvtr/Ivolve)
