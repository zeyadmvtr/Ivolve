#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/backend-data"
mkdir -p "${DATA_DIR}"

echo ">>> Cleaning up previous containers, networks, and volumes..."
docker rm -f frontend backend notification 2>/dev/null || true
docker network rm frontend-backend backend-notification 2>/dev/null || true
docker volume rm backend-logs notification-logs 2>/dev/null || true

echo ">>> 1. Creating bridge networks with separate subnets..."
docker network create --driver bridge --subnet 172.20.0.0/16 frontend-backend
docker network create --driver bridge --subnet 172.21.0.0/16 backend-notification

echo ">>> 2. Creating docker volumes for backend and notification logs..."
docker volume create backend-logs
docker volume create notification-logs

echo ">>> 3. Running notification container on backend-notification..."
docker run -d \
  --name notification \
  --network backend-notification \
  -v notification-logs:/app/logs \
  notification-service

echo ">>> 4. Running backend container on frontend-backend with bind mount and volumes..."
docker run -d \
  --name backend \
  --network frontend-backend \
  -e NOTIFICATION_URL=http://notification:5001/notify \
  -v backend-logs:/app/logs \
  -v "${DATA_DIR}:/app/data" \
  backend-service

echo ">>> 5. Connecting backend to backend-notification network..."
docker network connect backend-notification backend

echo ">>> 6. Running frontend container on frontend-backend publishing port 8080..."
docker run -d \
  --name frontend \
  --network frontend-backend \
  -p 8080:3000 \
  -e BACKEND_URL=http://backend:5000 \
  frontend-service

echo ">>> 7. Verifying running containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
