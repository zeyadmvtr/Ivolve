# Lab 7: Multi-Network Microservices, Volumes, and Bind Mounts Run Script (PowerShell)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataDir = Join-Path $ScriptDir "backend-data"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

Write-Host ">>> Cleaning up previous containers, networks, and volumes..." -ForegroundColor Yellow
docker rm -f frontend backend notification 2>$null | Out-Null
docker network rm frontend-backend backend-notification 2>$null | Out-Null
docker volume rm backend-logs notification-logs 2>$null | Out-Null

Write-Host ">>> 1. Creating bridge networks with separate subnets..." -ForegroundColor Cyan
docker network create --driver bridge --subnet 172.20.0.0/16 frontend-backend
docker network create --driver bridge --subnet 172.21.0.0/16 backend-notification

Write-Host ">>> 2. Creating docker volumes for backend and notification logs..." -ForegroundColor Cyan
docker volume create backend-logs
docker volume create notification-logs

Write-Host ">>> 3. Running notification container on backend-notification..." -ForegroundColor Cyan
docker run -d `
  --name notification `
  --network backend-notification `
  -v notification-logs:/app/logs `
  notification-service

Write-Host ">>> 4. Running backend container on frontend-backend with bind mount and volumes..." -ForegroundColor Cyan
docker run -d `
  --name backend `
  --network frontend-backend `
  -e NOTIFICATION_URL=http://notification:5001/notify `
  -v backend-logs:/app/logs `
  -v "${DataDir}:/app/data" `
  backend-service

Write-Host ">>> 5. Connecting backend to backend-notification network..." -ForegroundColor Cyan
docker network connect backend-notification backend

Write-Host ">>> 6. Running frontend container on frontend-backend publishing port 8080..." -ForegroundColor Cyan
docker run -d `
  --name frontend `
  --network frontend-backend `
  -p 8080:3000 `
  -e BACKEND_URL=http://backend:5000 `
  frontend-service

Write-Host ">>> 7. Verifying running containers..." -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
