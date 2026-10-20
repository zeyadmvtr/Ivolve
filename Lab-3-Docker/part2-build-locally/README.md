# Lab 3 - Part 2: Build Locally & Package with Java Runtime

This subfolder provides a lightweight Dockerfile using `eclipse-temurin:17-jre` that packages the locally pre-built JAR.

## Commands

```bash
# 1. Build locally on host
mvn clean package

# 2. Build image (app2)
docker build -t app2 .

# 3. Check size
docker images app2

# 4. Run container
docker run -it --name container2 -p 8080:8080 app2

# 5. Clean up
docker rm container2
docker rmi app2
```
