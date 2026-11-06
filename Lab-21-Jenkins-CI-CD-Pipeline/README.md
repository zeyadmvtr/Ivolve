# Lab 21: Jenkins Pipeline for Application Deployment

[![Jenkins](https://img.shields.io/badge/Jenkins-Pipeline-D24939.svg?logo=jenkins&logoColor=white)](https://www.jenkins.io/doc/book/pipeline/)
[![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![Trivy](https://img.shields.io/badge/Security-Trivy_Vulnerability_Scan-1904DA.svg)](https://trivy.dev/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployment-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)

This lab demonstrates how to construct an automated end-to-end **Declarative Jenkins CI/CD Pipeline** that builds, containerizes, scans, and deploys a Spring Boot application (`DemoApp`) to a Kubernetes cluster using least-privileged RBAC credentials.

---

## 🎯 Lab Objectives

- [x] **Clone source code and Dockerfile** from: [`https://github.com/Ibrahim-Adel15/DemoApp.git`](https://github.com/Ibrahim-Adel15/DemoApp.git).
- [x] **Automate the 7 Core CI/CD Processes**:
  1. **Build App**: Compile and package Java source code with Maven (`mvn clean package`).
  2. **Build Docker Image**: Build container image tagged with dynamic build number (`${DOCKER_HUB_USER}/demoapp:${BUILD_NUMBER}`).
  3. **Scan Docker Image**: Perform vulnerability scanning using **Trivy** (`trivy image --severity HIGH,CRITICAL`).
  4. **Push Image to DockerHub**: Authenticate and publish versioned artifact to Docker Hub registry.
  5. **Delete Image Locally**: Remove temporary local container image to conserve disk space.
  6. **Update Image in Deployment File**: Update `k8s/deployment.yaml` with the newly published image tag.
  7. **Deploy to Kubernetes Cluster**: Apply manifests into the `ivolve` namespace using the `jenkinsSA` ServiceAccount configured in Lab 19.
- [x] **Configure Pipeline Post Actions**: Implement structured notifications and workspace cleanup for `always`, `success`, and `failure` states.

---

## 💡 End-to-End CI/CD Pipeline Architecture

```
                    +-------------------------------------------------------------+
                    |                JENKINS DECLARATIVE PIPELINE                 |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | SCM Checkout: https://github.com/Ibrahim-Adel15/DemoApp.git |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 1. Build App: mvn clean package (Generates demo-0.0.1.jar)  |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 2. Build Image: docker build -t zeyadmvtr/demoapp:${BUILD} .|
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 3. Scan Image: trivy image --severity HIGH,CRITICAL         |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 4. Push Image: docker push zeyadmvtr/demoapp:${BUILD}       |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 5. Delete Local Image: docker rmi zeyadmvtr/demoapp:${BUILD}|
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 6. Update Manifest: sed k8s/deployment.yaml with new tag    |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | 7. Deploy to K8s: kubectl apply -f k8s/ -n ivolve           |
                    |    (Uses ServiceAccount jenkinsSA from Lab 19)              |
                    +-------------------------------------------------------------+
                                                   |
                                                   v
                    +-------------------------------------------------------------+
                    | Post Actions: always (cleanWs) | success (notif) | failure  |
                    +-------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-21-Jenkins-CI-CD-Pipeline/
├── k8s/
│   ├── deployment.yaml                  # Kubernetes deployment for DemoApp in 'ivolve' ns
│   └── service.yaml                     # NodePort service exposing port 8080 (NodePort 30088)
├── scripts/
│   └── 01-run-pipeline-simulation.sh    # Local/bash pipeline simulator executing all 7 steps
├── Jenkinsfile                          # Declarative multi-stage Jenkinsfile
└── README.md                            # Comprehensive documentation & walkthrough
```

---

## 🚀 Jenkins Pipeline Walkthrough (`Jenkinsfile`)

```groovy
pipeline {
    agent any

    environment {
        REPO_URL           = 'https://github.com/Ibrahim-Adel15/DemoApp.git'
        DOCKER_HUB_USER    = 'zeyadmvtr'
        IMAGE_NAME         = 'demoapp'
        IMAGE_TAG          = "${BUILD_NUMBER}"
        FULL_IMAGE         = "${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
        DOCKER_CREDENTIALS = 'dockerhub-credentials'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', url: "${REPO_URL}"
            }
        }
        stage('1. Build App') {
            steps {
                sh 'mvn clean package -DskipTests=false'
            }
        }
        stage('2. Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ."
            }
        }
        stage('3. Scan Docker Image') {
            steps {
                sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${FULL_IMAGE}"
            }
        }
        stage('4. Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }
        stage('5. Delete Image Locally') {
            steps {
                sh "docker rmi ${FULL_IMAGE} || true"
            }
        }
        stage('6. Update Image in Deployment File') {
            steps {
                sh """
                    sed -i.bak -E "s|image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:.*|image: ${FULL_IMAGE}|g" k8s/deployment.yaml
                """
            }
        }
        stage('7. Deploy to Kubernetes Cluster') {
            steps {
                sh """
                    kubectl apply -f k8s/deployment.yaml -n ivolve
                    kubectl apply -f k8s/service.yaml -n ivolve
                    kubectl rollout status deployment/demo-app -n ivolve --timeout=120s
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline complete. Cleaning up workspace..."
            cleanWs deleteDirs: true, notFailBuild: true
        }
        success {
            echo ">>> [SUCCESS] Build #${BUILD_NUMBER} deployed successfully!"
        }
        failure {
            echo ">>> [FAILURE] Build #${BUILD_NUMBER} failed! Check console logs."
        }
    }
}
```

---

## ⚡ Automated Simulation & Testing

Run the full pipeline simulation locally:

```bash
bash scripts/01-run-pipeline-simulation.sh
```

**Output:**
```
==========================================================
>>> Step 0: Cloning DemoApp from GitHub (https://github.com/Ibrahim-Adel15/DemoApp.git)
==========================================================
Cloning into 'pipeline_workspace'...
>>> Process 1: Build App (Maven clean package)
[INFO] BUILD SUCCESS
>>> Process 2: Build Docker Image (zeyadmvtr/demoapp:1)
Successfully built 4a7c819bd8
>>> Process 3: Scan Docker Image (Trivy Security Audit)
Total: 0 (HIGH: 0, CRITICAL: 0)
>>> Process 4: Push Image to DockerHub (Dry-Run / Push)
Command: docker push zeyadmvtr/demoapp:1
>>> Process 5: Delete Image Locally
Untagged: zeyadmvtr/demoapp:1
>>> Process 6: Update Image in Deployment File
    image: zeyadmvtr/demoapp:1
>>> Process 7: Deploy to Kubernetes Cluster (Namespace: ivolve)
deployment.apps/demo-app configured
service/demo-app-svc unchanged
==========================================================
>>> [SUCCESS] All 7 Pipeline stages completed successfully!
==========================================================
```
