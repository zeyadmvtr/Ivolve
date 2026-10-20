# Lab 3: Docker Image Comparison & Analysis

## 📊 Overview: Part 1 vs. Part 2

This document provides a comparative analysis of the two Docker containerization strategies implemented in Lab 3 for the Java Calculator application.

---

## ⚖️ Comparison Matrix

| Criterion | Approach 1: Build Inside Docker (`app1`) | Approach 2: Build Locally (`app2`) | Best Practice: Multi-Stage Build |
| :--- | :--- | :--- | :--- |
| **Image Name** | `app1` | `app2` | `app-multistage` |
| **Base Image** | `maven:3.9.6-eclipse-temurin-17` | `eclipse-temurin:17-jre` | Build: `maven` / Final: `eclipse-temurin:17-jre` |
| **Approximate Image Size** | **~650 MB - 850 MB** | **~220 MB - 260 MB** | **~220 MB - 260 MB** |
| **Build Environment** | Inside Docker container | Host machine (local Maven + JDK) | Inside Docker container (Stage 1) |
| **Host Tool Requirements** | Docker only (no Java/Maven required on host) | Docker + JDK 17 + Maven 3.8+ required on host | Docker only |
| **Includes Compiler / JDK?** | Yes (full JDK) | No (JRE runtime only) | No (JRE runtime only) |
| **Includes Maven / Build Tools?** | Yes (Maven binary, plugins, cache) | No | No |
| **Source Code in Final Image?** | Yes (`src/`, `pom.xml`, `~/.m2`) | No (only `calculator.jar`) | No (only `calculator.jar`) |
| **Security / Attack Surface** | Larger (more binaries, tools, shell utilities) | Minimal (only runtime needed for execution) | Minimal |
| **Deployment Speed** | Slower (larger transfer over network) | Faster (significantly smaller image transfer) | Faster |

---

## 🔬 In-Depth Analysis

### 1. Approach 1: Build Inside Docker (`Dockerfile.part1` / `app1`)

#### Workflow:
1. The Docker build context includes the complete application source code (`pom.xml` and `src/`).
2. Docker pulls a fat Maven + JDK 17 base image.
3. A non-root user is created for security.
4. Maven compiles the code, downloads dependencies to the container's local repository, and packages `target/calculator.jar`.
5. The container entrypoint executes `java -jar target/calculator.jar`.

#### Why is the image so large (~650 MB - 850 MB)?
- **Full JDK vs. JRE**: Contains compilers (`javac`), debuggers, header files, and profiling tools.
- **Maven & Dependencies**: Includes the Apache Maven runtime and all cached Maven plugins downloaded during build execution.
- **Source Code**: Contains uncompiled source files and build artifacts inside the container layers.

#### Pros:
- **Zero Host Dependencies**: Developers and CI agents don't need Java or Maven installed; only Docker engine is required.
- **Complete Reproducibility**: Everyone builds using the exact same Maven version and JDK vendor/version defined in the Dockerfile.

#### Cons:
- Bloated image size.
- Increased network latency during registry pushes and deployments.
- Larger security surface due to extraneous packages.

---

### 2. Approach 2: Build Locally (`Dockerfile.part2` / `app2`)

#### Workflow:
1. The developer or CI runner compiles and packages the JAR on the host machine (`mvn clean package`).
2. Docker pulls a lightweight Java 17 JRE runtime image.
3. A non-root user is created for security.
4. Only the pre-built `target/calculator.jar` (~4 KB) is copied into the container.
5. The container entrypoint executes `java -jar /app/calculator.jar`.

#### Why is the image so small (~220 MB - 260 MB)?
- **JRE Only**: Contains only the Java Runtime Environment needed to run bytecode, stripping out compiler and developer tooling.
- **No Build Tools**: Maven, plugin caches, and intermediate build files are never added to the Docker layers.
- **Single Artifact**: Only the compiled binary is copied into the container filesystem.

#### Pros:
- **Significantly smaller image**: Over 60-70% size reduction compared to `app1`.
- **Hardened security**: Fewer packages and tools installed in production containers minimize common vulnerabilities (CVEs).
- **Fast pushes and pulls**: Quick deployment across cluster nodes.

#### Cons:
- **Host coupling**: The host machine must have the correct JDK and Maven versions installed.
- **Risk of environmental drift**: If the developer machine runs a different Java version than the CI/CD pipeline, build inconsistencies may arise.

---

## 💡 Industry Best Practice: Multi-Stage Build

To achieve the best of both worlds (zero host requirements from Approach 1 AND lightweight images from Approach 2), production setups typically employ a **Multi-Stage Dockerfile**:

```dockerfile
# Stage 1: Build the artifact in a full build environment
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package

# Stage 2: Create a minimal production runtime image
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd -r appuser && useradd -r -g appuser -u 1001 -m appuser
COPY --from=builder /app/target/calculator.jar /app/calculator.jar
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/calculator.jar"]
```

This yields a lightweight final image (~220 MB) while keeping the entire build reproducible inside Docker.
