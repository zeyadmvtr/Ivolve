# Lab 3: Creating a Docker Image for a Java Application

This project covers containerizing a Java application using two distinct approaches as specified in the lab requirements:
- **Part 1: Build Inside Docker** (Compiling inside a Maven build image).
- **Part 2: Build Locally** (Compiling locally with Maven and packaging into a lightweight Java 17 JRE runtime image).
- **Bonus**: Size comparison and detailed differences between both approaches (see [COMPARISON.md](COMPARISON.md)).

---

## 🗂️ Project Structure

```
Lab-3-Docker/
├── Dockerfile.part1                    # Part 1 Dockerfile (Build Inside Docker)
├── Dockerfile.part2                    # Part 2 Dockerfile (Build Locally)
├── COMPARISON.md                       # Comprehensive comparison & analysis
├── README.md                           # Lab 3 Guide
├── pom.xml
├── src/
│   ├── main/java/com/example/calculator/
│   └── test/java/com/example/calculator/
├── part1-build-inside-docker/          # Standalone folder for Part 1
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
└── part2-build-locally/                # Standalone folder for Part 2
    ├── Dockerfile
    ├── pom.xml
    └── src/
```

---

## ⚙️ Prerequisites

- **Docker Desktop / Docker Engine**: Running and accessible from CLI.
  ```bash
  docker --version
  ```
- **Java 17 & Maven 3.8+** *(Required for Part 2 local build)*:
  ```bash
  java -version
  mvn -version
  ```

---

## 🐳 Part 1: Build Inside Docker

In this approach, the source code is copied into a Maven container where it is compiled and packaged during the Docker image build.

### 1. Build the Docker Image (`app1`)

```bash
docker build -f Dockerfile.part1 -t app1 .
```
*(Or inside the standalone subfolder: `cd part1-build-inside-docker && docker build -t app1 .`)*

### 2. Inspect Image Size

```bash
docker images app1
```

**Expected Size:** Approximately **~650 MB - 850 MB** (due to Maven binaries, full JDK, plugins, and dependencies).

### 3. Run Container (`container1`) & Verify Application

Run the container interactively:

```bash
docker run -it --name container1 -p 8080:8080 app1
```

**Verification:**
Enter numbers when prompted:
```
Enter first number: 12
Enter second number: 3
a = 12.0, b = 3.0
Sum: 15.0
Subtract: 9.0
Multiply: 36.0
Divide: 4.0
```

### 4. Cleanup Container and Image

```bash
docker rm container1
docker rmi app1
```

---

## 🚀 Part 2: Build Locally

In this approach, the application is compiled on the host machine using Maven. The resulting pre-built JAR is then copied into a slim Java 17 runtime container.

### 1. Build the Application Locally

```bash
mvn clean package
```
This generates the executable JAR at `target/calculator.jar`.

### 2. Build the Docker Image (`app2`)

```bash
docker build -f Dockerfile.part2 -t app2 .
```
*(Or inside the standalone subfolder: `cd part2-build-locally && mvn clean package && docker build -t app2 .`)*

### 3. Inspect Image Size

```bash
docker images app2
```

**Expected Size:** Approximately **~220 MB - 260 MB** (only the JRE and the single ~4 KB JAR).

### 4. Run Container (`container2`) & Verify Application

```bash
docker run -it --name container2 -p 8080:8080 app2
```

**Verification:**
Enter numbers when prompted:
```
Enter first number: 50
Enter second number: 5
a = 50.0, b = 5.0
Sum: 55.0
Subtract: 45.0
Multiply: 250.0
Divide: 10.0
```

### 5. Cleanup Container and Image

```bash
docker rm container2
docker rmi app2
```

---

## 🏆 Bonus: Comparison Summary

| Metric | Part 1 (`app1`) | Part 2 (`app2`) |
| :--- | :--- | :--- |
| **Base Image** | `maven:3.9.6-eclipse-temurin-17` | `eclipse-temurin:17-jre` |
| **Image Size** | **~650 MB - 850 MB** | **~220 MB - 260 MB** |
| **Build Location** | Inside container | Local host machine |
| **Host Tooling Needed** | Docker only | Docker + Maven + JDK 17 |
| **Non-Root User** | `appuser` (UID 1001) | `appuser` (UID 1001) |
| **Exposed Port** | 8080 | 8080 |
| **Primary Advantage** | Standardized, self-contained build | Much smaller footprint & smaller attack surface |

👉 **Read the full detailed breakdown in [COMPARISON.md](COMPARISON.md)**.
