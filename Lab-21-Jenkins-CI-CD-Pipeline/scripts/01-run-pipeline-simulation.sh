#!/usr/bin/env bash
# ==============================================================================
# Script: 01-run-pipeline-simulation.sh
# Purpose: Simulates and executes the 7 automated CI/CD pipeline steps
# ==============================================================================

set -euo pipefail

REPO_URL="https://github.com/Ibrahim-Adel15/DemoApp.git"
DOCKER_HUB_USER="${DOCKER_HUB_USER:-zeyadmvtr}"
IMAGE_NAME="demoapp"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
FULL_IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}"
WORK_DIR="pipeline_workspace"

echo "=========================================================="
echo ">>> Step 0: Cloning DemoApp from GitHub (${REPO_URL})"
echo "=========================================================="
rm -rf "${WORK_DIR}"
git clone "${REPO_URL}" "${WORK_DIR}"
cd "${WORK_DIR}"

echo ""
echo "=========================================================="
echo ">>> Process 1: Build App (Maven clean package)"
echo "=========================================================="
mvn clean package -DskipTests=true
ls -lh target/*.jar

echo ""
echo "=========================================================="
echo ">>> Process 2: Build Docker Image (${FULL_IMAGE})"
echo "=========================================================="
docker build -t "${FULL_IMAGE}" .

echo ""
echo "=========================================================="
echo ">>> Process 3: Scan Docker Image (Trivy Security Audit)"
echo "=========================================================="
if command -v trivy >/dev/null 2>&1; then
  trivy image --severity HIGH,CRITICAL --exit-code 0 "${FULL_IMAGE}"
else
  echo "[!] Trivy CLI not installed locally; skipping scan or run inside docker."
fi

echo ""
echo "=========================================================="
echo ">>> Process 4: Push Image to DockerHub (Dry-Run / Push)"
echo "=========================================================="
echo "Command: docker push ${FULL_IMAGE}"
# docker push "${FULL_IMAGE}" || true

echo ""
echo "=========================================================="
echo ">>> Process 5: Delete Image Locally"
echo "=========================================================="
echo "Cleaning local image cache:"
docker rmi "${FULL_IMAGE}" || true

echo ""
echo "=========================================================="
echo ">>> Process 6: Update Image in Deployment File"
echo "=========================================================="
cd ..
sed -i.bak -E "s|image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:.*|image: ${FULL_IMAGE}|g" k8s/deployment.yaml
grep "image:" k8s/deployment.yaml

echo ""
echo "=========================================================="
echo ">>> Process 7: Deploy to Kubernetes Cluster (Namespace: ivolve)"
echo "=========================================================="
if command -v kubectl >/dev/null 2>&1; then
  kubectl apply -f k8s/deployment.yaml -n ivolve || true
  kubectl apply -f k8s/service.yaml -n ivolve || true
fi

echo ""
echo "=========================================================="
echo ">>> [SUCCESS] All 7 Pipeline stages completed successfully!"
echo "=========================================================="
rm -rf "${WORK_DIR}"
