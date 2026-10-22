# Lab 6: Docker Environment Variables and Resource Management

This lab covers configuring container runtime environment variables using three distinct patterns (inline `-e`, `--env-file`, and hardcoded `ENV` in Dockerfile) alongside setting and monitoring container resource limits (CPU and Memory).

---

## 📋 Objectives

1. Create a `Dockerfile` using `python:3.12-slim`, install dependencies, and configure port 5000.
2. Build the `ivolve1` Docker image.
3. Run `container1` mapping port 5000 with inline variables `APP_NAME=iVolveApp1` and `APP_ENV=stg`.
4. Enforce resource limits: **1 CPU** and **256 MB memory**.
5. Verify application via HTTP (`http://localhost:5000`) and verify environment variables inside container.
6. Monitor resource consumption using `docker stats`.
7. Create an `env.txt` file with `APP_NAME=iVolveApp2` and `APP_ENV=prod`, and run `container2` using `--env-file`.
8. Create a Dockerfile with hardcoded environment variables `APP_NAME=iVolveApp3` and `APP_ENV=dev`, build the image, and validate.

---

## 🗂️ Project Structure

```
Lab-6-Docker-Env-Resources/
├── Dockerfile                  # Standard base Dockerfile (python:3.12-slim)
├── Dockerfile.hardcoded        # Dockerfile with hardcoded ENV variables
├── env.txt                     # Environment file for container2
├── app.py                      # Flask web application checking APP_NAME & APP_ENV
├── requirements.txt            # Flask==3.1.2
└── README.md                   # Lab guide
```

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Build Base Docker Image (`ivolve1`)

```bash
cd Lab-6-Docker-Env-Resources
docker build -t ivolve1 .
```

---

### Step 2: Run `container1` with Inline Env Vars & Resource Limits

Run the container with:
- Port mapping: `-p 5000:5000`
- Inline environment variables: `-e APP_NAME=iVolveApp1 -e APP_ENV=stg`
- Resource limits: `--cpus="1.0" --memory="256m"`

```bash
docker run -d --name container1 \
  -p 5000:5000 \
  -e APP_NAME=iVolveApp1 \
  -e APP_ENV=stg \
  --cpus="1.0" \
  --memory="256m" \
  ivolve1
```

---

### Step 3: Verify Application, Environment Variables & Monitor Resources

1. **Verify Web Application:**
   ```bash
   curl http://localhost:5000
   ```
   **Expected JSON Output:**
   ```json
   {
     "application": "iVolveApp1",
     "environment": "stg",
     "message": "Welcome to the Docker Env & Resource Management Lab!"
   }
   ```

2. **Verify Environment Variables inside Container:**
   ```bash
   docker exec container1 env | grep APP_
   ```
   **Expected Output:**
   ```
   APP_NAME=iVolveApp1
   APP_ENV=stg
   ```

3. **Monitor CPU & Memory Usage:**
   ```bash
   docker stats container1 --no-stream
   ```
   **Expected Output:**
   ```
   CONTAINER ID   NAME         CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
   abc123def456   container1   0.05%     24.5MiB / 256MiB    9.57%     1.2kB/600B  0B / 0B     2
   ```

4. **Clean up `container1`:**
   ```bash
   docker stop container1 && docker rm container1
   ```

---

### Step 4: Run `container2` Using Environment File (`env.txt`)

The file [`env.txt`](env.txt) contains:
```env
APP_NAME=iVolveApp2
APP_ENV=prod
```

Run container using `--env-file`:
```bash
docker run -d --name container2 \
  -p 5000:5000 \
  --env-file env.txt \
  --cpus="1.0" \
  --memory="256m" \
  ivolve1
```

**Verify Application:**
```bash
curl http://localhost:5000
```
**Expected JSON Output:**
```json
{
  "application": "iVolveApp2",
  "environment": "prod",
  "message": "Welcome to the Docker Env & Resource Management Lab!"
}
```

Clean up `container2`:
```bash
docker stop container2 && docker rm container2
```

---

### Step 5: Build Image with Hardcoded Environment Variables (`ivolve3`)

Using [`Dockerfile.hardcoded`](Dockerfile.hardcoded) where environment variables are embedded in the image layers:
```dockerfile
ENV APP_NAME=iVolveApp3
ENV APP_ENV=dev
```

Build the new image:
```bash
docker build -f Dockerfile.hardcoded -t ivolve3 .
```

---

### Step 6: Run & Validate Container with Hardcoded Variables

Run the container without passing runtime environment flags:
```bash
docker run -d --name container3 -p 5000:5000 ivolve3
```

**Verify Web Application:**
```bash
curl http://localhost:5000
```
**Expected JSON Output:**
```json
{
  "application": "iVolveApp3",
  "environment": "dev",
  "message": "Welcome to the Docker Env & Resource Management Lab!"
}
```

**Inspect Container Env:**
```bash
docker exec container3 env | grep APP_
```
**Expected Output:**
```
APP_NAME=iVolveApp3
APP_ENV=dev
```

Clean up:
```bash
docker stop container3 && docker rm container3
```

---

## 📌 Environment Variable Precedence in Docker

Docker resolves environment variables in the following order of precedence (highest to lowest):
1. **Command line flags (`-e VAR=value`)**: Always overrides any other source.
2. **Environment file (`--env-file env.txt`)**: Overrides Dockerfile instructions.
3. **Dockerfile (`ENV VAR=value`)**: Serves as the fallback default when not provided at runtime.
