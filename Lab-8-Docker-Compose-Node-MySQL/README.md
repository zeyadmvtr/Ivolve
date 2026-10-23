# Lab 8: Containerized Node.js and MySQL Stack Using Docker Compose

This lab demonstrates orchestrating a multi-container full-stack application comprising a Node.js Express web service and a MySQL 8 relational database using **Docker Compose**. It covers service health checks, custom bridge networking, persistent volume management for database data and application access logs, and publishing tagged container images to **Docker Hub**.

---

## 📋 Objectives

1. **Docker Compose Orchestration**: Author a declarative `docker-compose.yml` to define, build, and run the multi-container application.
2. **Database Provisioning**:
   - Use official `mysql:8.0` image.
   - Configure root authentication and automatic creation of the `ivolve` database.
   - Implement database readiness health checks (`mysqladmin ping`).
3. **Application Service Configuration**:
   - Build from `Dockerfile` (`node:18-alpine`).
   - Map port `3000:3000`.
   - Pass database connection credentials via environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`).
   - Configure container dependency conditions (`depends_on.condition: service_healthy`).
4. **Volume Management**:
   - Database data persistence: `db_data` volume mounted to `/var/lib/mysql`.
   - Application logs persistence: `app_logs` volume mounted to `/app/logs/` (capturing Morgan HTTP access logs).
5. **Custom Network**: Create a custom bridge network named `ivolve-net` for isolated inter-service communication.
6. **Testing & Validation**: Verify database connection retry logic, `/health` endpoint, `/ready` endpoint, static asset delivery, and volume persistence.
7. **Docker Hub Publication**: Build, tag, and push the application image to Docker Hub (`zeyadmvtr/ivolve-app`).

---

## 📐 Architecture & Docker Compose Overview

```
+-----------------------------------------------------------------------------------+
|                                 Docker Host                                       |
|                                                                                   |
|   Browser / HTTP Client                                                           |
|             |                                                                     |
|      (Port 3000:3000)                                                             |
|             v                                                                     |
|   +--------------------+                          +--------------------+          |
|   |     ivolve-app     |                          |     ivolve-db      |          |
|   |  (Node.js Express) |                          |    (MySQL 8.0)     |          |
|   +--------------------+                          +--------------------+          |
|             |                                                |                    |
|             +-----------------------+------------------------+                    |
|                                     |                                             |
|                             Network: ivolve-net                                   |
|                               (Custom Bridge)                                     |
|                                                                                   |
|             |                                                |                    |
|             v                                                v                    |
|   +--------------------+                          +--------------------+          |
|   |      app_logs      |                          |      db_data       |          |
|   |    (Docker Vol)    |                          |    (Docker Vol)    |          |
|   |     /app/logs/     |                          |  /var/lib/mysql    |          |
|   +--------------------+                          +--------------------+          |
+-----------------------------------------------------------------------------------+
```

---

## 🗂️ Project Structure

```
Lab-8-Docker-Compose-Node-MySQL/
├── frontend/
│   ├── assets/
│   │   └── ivolve-logo.png         # Static company brand assets
│   └── index.html                  # Frontend HTML interface
├── db.js                           # Database connection & table initializer helper
├── server.js                       # Express server with retry connection & health routes
├── package.json                    # Node.js dependencies (express, mysql2, morgan)
├── Dockerfile                      # Node.js 18 Alpine containerfile
├── docker-compose.yml              # Multi-container orchestration configuration
└── README.md                       # Comprehensive lab documentation
```

---

## ⚙️ Docker Compose Specification (`docker-compose.yml`)

```yaml
services:
  db:
    image: mysql:8.0
    container_name: ivolve-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: ivolve
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - ivolve-net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-prootpassword"]
      interval: 5s
      timeout: 5s
      retries: 10

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ivolve-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DB_HOST: db
      DB_USER: root
      DB_PASSWORD: rootpassword
      DB_NAME: ivolve
      PORT: 3000
    volumes:
      - app_logs:/app/logs
    networks:
      - ivolve-net
    depends_on:
      db:
        condition: service_healthy

networks:
  ivolve-net:
    name: ivolve-net
    driver: bridge

volumes:
  db_data:
    name: db_data
  app_logs:
    name: app_logs
```

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Start Stack with Docker Compose

Build the application image and start all services in detached mode:

```bash
cd Lab-8-Docker-Compose-Node-MySQL

docker compose up --build -d
```

### Step 2: Verify Service Status

Check that the containers are healthy and running:

```bash
docker compose ps
```

**Output:**
```
NAME         IMAGE                                 COMMAND                  SERVICE   CREATED          STATUS                    PORTS
ivolve-app   lab-8-docker-compose-node-mysql-app   "docker-entrypoint.s…"   app       40 seconds ago   Up 23 seconds             0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
ivolve-db    mysql:8.0                             "docker-entrypoint.s…"   db        40 seconds ago   Up 39 seconds (healthy)   3306/tcp, 33060/tcp
```

---

### Step 3: Inspect Application Startup Logs

Verify that the Node.js application successfully connected to MySQL and verified the `ivolve` database:

```bash
docker logs ivolve-app
```

**Output:**
```
🔄 Attempting to connect to MySQL...
✅ Connected to MySQL and 'ivolve' DB found.
🚀 Server started on http://0.0.0.0:3000
```

---

### Step 4: Verify Application Endpoints

1. **Health Check (`/health`):**
   ```bash
   curl http://localhost:3000/health
   ```
   **Output:**
   ```
   🚀 iVolve web app is working! Keep calm and code on! 🎉
   ```

2. **Readiness Check (`/ready`):**
   ```bash
   curl http://localhost:3000/ready
   ```
   **Output:**
   ```
   👍 iVolve web app is ready to rock and roll! 🤘
   ```

3. **Frontend Landing Page (`/`):**
   ```bash
   curl -s http://localhost:3000/ | grep "<title>"
   ```
   **Output:**
   ```html
   <title>iVolve | Global Cloud Company</title>
   ```

---

### Step 5: Verify Persistent Logging & Volumes

Check that Morgan HTTP requests are persisted inside the `app_logs` volume at `/app/logs/access.log`:

```bash
docker exec ivolve-app cat /app/logs/access.log
```

**Output:**
```
172.19.0.1 - - [23/Oct/2026:02:47:02 +0000] "GET /health HTTP/1.1" 200 59 "-" "curl/8.18.0"
172.19.0.1 - - [23/Oct/2026:02:47:02 +0000] "GET /ready HTTP/1.1" 200 51 "-" "curl/8.18.0"
172.19.0.1 - - [23/Oct/2026:02:47:02 +0000] "GET / HTTP/1.1" 200 2888 "-" "curl/8.18.0"
```

Verify volumes:
```bash
docker volume ls | grep -E 'app_logs|db_data'
```
**Output:**
```
local     app_logs
local     db_data
```

---

### Step 6: Build, Tag & Push to Docker Hub

1. Tag the application image with the Docker Hub username (`zeyadmvtr`):
   ```bash
   docker tag lab-8-docker-compose-node-mysql-app:latest zeyadmvtr/ivolve-app:latest
   docker tag lab-8-docker-compose-node-mysql-app:latest zeyadmvtr/ivolve-app:v1.0
   ```

2. Push the tagged images to Docker Hub repository:
   ```bash
   docker push zeyadmvtr/ivolve-app:latest
   docker push zeyadmvtr/ivolve-app:v1.0
   ```

**Output:**
```
The push refers to repository [docker.io/zeyadmvtr/ivolve-app]
latest: digest: sha256:db691a4c52ca839715accea30fbdae52a6a9773a7a8656a989229b6ce326bc0b size: 856
v1.0: digest: sha256:db691a4c52ca839715accea30fbdae52a6a9773a7a8656a989229b6ce326bc0b size: 856
```

👉 **Docker Hub Repository**: [https://hub.docker.com/r/zeyadmvtr/ivolve-app](https://hub.docker.com/r/zeyadmvtr/ivolve-app)

---

## 🧹 Tear Down

To stop and remove containers, networks, and persistent volumes:

```bash
docker compose down -v
```
