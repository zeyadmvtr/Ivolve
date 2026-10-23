# Lab 7: Multi-Network Microservices, Volumes, and Bind Mounts

This lab demonstrates containerizing a three-tier microservices architecture using custom Docker bridge networks with dedicated subnets for strict network isolation, Docker named volumes for centralized logging, and a host bind mount for persistent application data storage.

---

## 📋 Objectives

1. **Clone & Dockerize Services**: Containerize three microservices (Frontend, Backend, and Notification) using lightweight Python images (`python:3.12-slim`).
2. **Network Isolation**: Create two custom bridge networks with separate CIDR subnets:
   - `frontend-backend` (`172.20.0.0/16`)
   - `backend-notification` (`172.21.0.0/16`)
3. **Volume Management**: Create named volumes to persist service logs:
   - `backend-logs` mapped to `/app/logs`
   - `notification-logs` mapped to `/app/logs`
4. **Host Bind Mount**: Create a host directory (`backend-data/`) bind-mounted to `/app/data` to persist message storage (`messages.json`).
5. **Multi-Network Routing**:
   - Run `notification` exclusively on `backend-notification`.
   - Run `backend` attached to both `frontend-backend` and `backend-notification`.
   - Run `frontend` on `frontend-backend`, publishing port `8080:3000`.
6. **End-to-End Verification**: Test message submission, message retrieval, host data persistence, log inspection, and verify network isolation (Frontend cannot reach Notification).

---

## 📐 Architecture & Network Topology

```
+---------------------------------------------------------------------------------------+
|                                    Docker Host                                        |
|                                                                                       |
|   Browser / Client                                                                    |
|          |                                                                            |
|   (Port 8080:3000)                                                                    |
|          v                                                                            |
|   +---------------+           +---------------+           +--------------------+      |
|   |   frontend    |           |    backend    |           |    notification    |      |
|   |  (Port 3000)  |           |  (Port 5000)  |           |    (Port 5001)     |      |
|   +---------------+           +---------------+           +--------------------+      |
|          |                            |                              |                |
|          |   frontend-backend         |      backend-notification    |                |
|          +----------------------------+------------------------------+                |
|             Subnet: 172.20.0.0/16                 Subnet: 172.21.0.0/16               |
|                                                                                       |
|                                       |                              |                |
|                                       |                              |                |
|                              +-----------------+            +-----------------+       |
|                              |  backend-logs   |            |notification-logs|       |
|                              |  (Docker Vol)   |            |  (Docker Vol)   |       |
|                              +-----------------+            +-----------------+       |
|                                       |                                               |
|                              +-----------------+                                      |
|                              |  ./backend-data |                                      |
|                              |  (Bind Mount)   |                                      |
|                              +-----------------+                                      |
+---------------------------------------------------------------------------------------+
```

### Security & Isolation Principle
- **Frontend** and **Backend** communicate securely over `frontend-backend`.
- **Backend** and **Notification** communicate over `backend-notification`.
- **Frontend cannot reach Notification**: They do not share a common network.

---

## 🗂️ Project Structure

```
Lab-7-Multi-Network-Microservices/
├── backend/
│   ├── app.py                      # Flask backend API (data storage + notification sender)
│   ├── Dockerfile                  # Python 3.12-slim containerfile
│   └── requirements.txt            # Flask, requests
├── frontend/
│   ├── app.py                      # Flask web interface (communicates with backend)
│   ├── Dockerfile                  # Python 3.12-slim containerfile
│   └── requirements.txt            # Flask, requests
├── notification/
│   ├── app.py                      # Flask notification receiver & file logger
│   ├── Dockerfile                  # Python 3.12-slim containerfile
│   └── requirements.txt            # Flask
├── backend-data/                   # Host directory for bind mount (/app/data/messages.json)
├── run-lab7.sh                     # Automated execution script (Linux / WSL / macOS)
├── run-lab7.ps1                    # Automated execution script (Windows PowerShell)
└── README.md                       # Comprehensive documentation
```

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Build Docker Images

Navigate to the lab directory and build images for all three services:

```bash
cd Lab-7-Multi-Network-Microservices

# Build Frontend Image
docker build -t frontend-service ./frontend

# Build Backend Image
docker build -t backend-service ./backend

# Build Notification Image
docker build -t notification-service ./notification
```

---

### Step 2: Create Custom Bridge Networks with Subnets

Create isolated networks with distinct CIDR blocks:

```bash
# Network 1: Frontend <-> Backend
docker network create --driver bridge --subnet 172.20.0.0/16 frontend-backend

# Network 2: Backend <-> Notification
docker network create --driver bridge --subnet 172.21.0.0/16 backend-notification
```

Verify networks:
```bash
docker network ls
```

---

### Step 3: Create Docker Volumes for Logging

Create named volumes to isolate and persist application logs:

```bash
docker volume create backend-logs
docker volume create notification-logs
```

---

### Step 4: Prepare Host Directory for Data Persistence

Create the host directory used for the backend bind mount:

```bash
mkdir -p backend-data
```

---

### Step 5: Run Notification Container

Run the notification service attached only to the `backend-notification` network:

```bash
docker run -d \
  --name notification \
  --network backend-notification \
  -v notification-logs:/app/logs \
  notification-service
```

---

### Step 6: Run Backend Container with Bind Mount and Dual Networks

1. Start the backend container on `frontend-backend`:
   ```bash
   docker run -d \
     --name backend \
     --network frontend-backend \
     -e NOTIFICATION_URL=http://notification:5001/notify \
     -v backend-logs:/app/logs \
     -v "$(pwd)/backend-data:/app/data" \
     backend-service
   ```

2. Connect backend to the `backend-notification` network:
   ```bash
   docker network connect backend-notification backend
   ```

---

### Step 7: Run Frontend Container

Publish port `8080` to the host and connect frontend to `frontend-backend`:

```bash
docker run -d \
  --name frontend \
  --network frontend-backend \
  -p 8080:3000 \
  -e BACKEND_URL=http://backend:5000 \
  frontend-service
```

---

### Step 8: Verification & Testing

#### 1. Verify Container States
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
**Expected Output:**
```
NAMES          STATUS         PORTS
frontend       Up 2 minutes   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp
backend        Up 2 minutes   5000/tcp
notification   Up 2 minutes   5001/tcp
```

#### 2. Access Web Interface
Open your browser at `http://localhost:8080` or execute:
```bash
curl -s http://localhost:8080
```

#### 3. Submit Messages via POST
```bash
curl -s -L -X POST http://localhost:8080/send -d "message=Welcome to Lab 7 Microservices"
curl -s -L -X POST http://localhost:8080/send -d "message=Docker Networking and Volumes Test"
```

#### 4. Retrieve Messages
```bash
curl -s http://localhost:8080/ | grep "<li>"
```
**Expected Output:**
```html
<li>Welcome to Lab 7 Microservices</li>
<li>Docker Networking and Volumes Test</li>
```

#### 5. Verify Bind Mount Persistence on Host
Inspect the host directory `backend-data/messages.json`:
```bash
cat backend-data/messages.json
```
**Output:**
```json
[
  "Welcome to Lab 7 Microservices",
  "Docker Networking and Volumes Test"
]
```

#### 6. Verify Centralized Volume Logs
- **Backend Log:**
  ```bash
  docker exec backend cat /app/logs/backend.log
  ```
  ```
  INFO Received request to retrieve messages
  INFO Message created successfully: Welcome to Lab 7 Microservices
  INFO Notification sent successfully
  INFO Message created successfully: Docker Networking and Volumes Test
  INFO Notification sent successfully
  ```

- **Notification Log:**
  ```bash
  docker exec notification cat /app/logs/notification.log
  ```
  ```
  INFO Notification received for message: Welcome to Lab 7 Microservices
  INFO Notification received for message: Docker Networking and Volumes Test
  ```

---

### Step 9: Verify Network Isolation

Test that the frontend **cannot** access the notification service:

```bash
docker exec frontend python -c "
import requests
try:
    requests.get('http://notification:5001/health', timeout=2)
except Exception as e:
    print('Network isolation verified! Notification unreachable from Frontend.')
"
```
**Output:**
```
Network isolation verified! Notification unreachable from Frontend.
```

---

## 🧹 Cleanup

To clean up all containers, custom networks, and volumes:

```bash
docker rm -f frontend backend notification
docker network rm frontend-backend backend-notification
docker volume rm backend-logs notification-logs
```
