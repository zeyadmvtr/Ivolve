# Lab 3 - Part 1: Build Inside Docker

This subfolder provides a self-contained environment to build and run the Java application directly inside Docker using a Maven base image.

## Commands

```bash
# 1. Build image (app1)
docker build -t app1 .

# 2. Check size
docker images app1

# 3. Run container
docker run -it --name container1 -p 8080:8080 app1

# 4. Clean up
docker rm container1
docker rmi app1
```
