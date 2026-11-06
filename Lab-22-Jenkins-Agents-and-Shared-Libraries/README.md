# Lab 22: CI/CD Pipeline Implementation with Jenkins Agents and Shared Libraries

[![Jenkins](https://img.shields.io/badge/Jenkins-Distributed_Agents-D24939.svg?logo=jenkins&logoColor=white)](https://www.jenkins.io/doc/book/managing/nodes/)
[![Shared Library](https://img.shields.io/badge/Architecture-Shared_Libraries-blue.svg)](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
[![Docker](https://img.shields.io/badge/Containerization-Docker_Agent-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-CD_Rollout-326CE5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)

This lab demonstrates how to design a scalable, enterprise-grade CI/CD pipeline using **Jenkins Distributed Agents (Slave Nodes)** and modular, reusable **Jenkins Shared Libraries** (`buildApp`, `buildImage`, and `deployOnK8s`).

---

## 🎯 Lab Objectives

- [x] **Clone Dockerfile and Source Code** from: [`https://github.com/Ibrahim-Adel15/DemoApp.git`](https://github.com/Ibrahim-Adel15/DemoApp.git).
- [x] **Create 3 Modular Jenkins Shared Libraries**:
  1. **`buildApp`** (`shared-library/vars/buildApp.groovy`): Executes unit tests and packages the Java Spring Boot application with Maven.
  2. **`buildImage`** (`shared-library/vars/buildImage.groovy`): Builds the Docker image, executes a security CVE scan with Trivy, pushes to Docker Hub, and purges the local image.
  3. **`deployOnK8s`** (`shared-library/vars/deployOnK8s.groovy`): Dynamically updates the Kubernetes deployment manifest and deploys the workload to the cluster.
- [x] **Refactor Jenkins Pipeline**: Update `Jenkinsfile` to import `@Library('ivolve-shared-library')` and invoke the reusable steps.
- [x] **Configure Jenkins Slave Node**: Configure and run a dedicated build worker agent with label `slave-node` to offload workloads from the Jenkins controller.

---

## 💡 Architecture & Distributed Build Model

```
+---------------------------------------------------------------------------------------------------+
|                                  JENKINS CONTROLLER (MASTER)                                      |
|                                                                                                   |
|   - Stores Pipeline Definitions & Credentials (DockerHub, Kubeconfig)                             |
|   - Loads Global Shared Library: @Library('ivolve-shared-library')                                 |
|   - Schedules Jobs to Labeled Agents (label: 'slave-node')                                        |
+---------------------------------------------------------------------------------------------------+
                                                  |
                                                  | Dispatches build tasks via SSH / JNLP
                                                  v
+---------------------------------------------------------------------------------------------------+
|                            JENKINS WORKER NODE (SLAVE: 'slave-node')                              |
|                                                                                                   |
|   +-------------------------------------------------------------------------------------------+   |
|   | 1. buildApp():                                                                            |   |
|   |    - Executes 'mvn test'                                                                  |   |
|   |    - Executes 'mvn clean package' -> target/demo-0.0.1.jar                                |   |
|   +-------------------------------------------------------------------------------------------+   |
|                                                 |                                                 |
|                                                 v                                                 |
|   +-------------------------------------------------------------------------------------------+   |
|   | 2. buildImage():                                                                          |   |
|   |    - docker build -t zeyadmvtr/demoapp:${BUILD_NUMBER}                                    |   |
|   |    - trivy image --severity HIGH,CRITICAL                                                 |   |
|   |    - docker push to Docker Hub                                                            |   |
|   |    - docker rmi to free up agent disk space                                               |   |
|   +-------------------------------------------------------------------------------------------+   |
|                                                 |                                                 |
|                                                 v                                                 |
|   +-------------------------------------------------------------------------------------------+   |
|   | 3. deployOnK8s():                                                                         |   |
|   |    - Updates k8s/deployment.yaml with new tag                                             |   |
|   |    - kubectl apply -f k8s/ -n ivolve                                                      |   |
|   |    - Monitors rollout status                                                              |   |
|   +-------------------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------------------+
```

---

## 📁 Directory Structure

```
Lab-22-Jenkins-Agents-and-Shared-Libraries/
├── shared-library/
│   └── vars/
│       ├── buildApp.groovy              # Reusable library: Unit tests & Maven package
│       ├── buildImage.groovy            # Reusable library: Build, scan, push, purge
│       └── deployOnK8s.groovy           # Reusable library: Manifest update & K8s deploy
├── agent-setup/
│   ├── Dockerfile.agent                 # Custom slave image with JDK17, Maven, Docker, Trivy, Kubectl
│   └── docker-compose.agent.yml         # Containerized SSH slave agent
├── k8s/
│   └── deployment.yaml                  # Target deployment manifest
├── scripts/
│   ├── 01-setup-agent.sh                # Launches containerized slave agent
│   └── 02-test-shared-libraries.sh      # Validates shared library syntax and modules
├── Jenkinsfile                          # Pipeline consuming shared libraries on 'slave-node'
└── README.md                            # Comprehensive documentation & walkthrough
```

---

## 🚀 Shared Library Implementations

### 1. `shared-library/vars/buildApp.groovy`
```groovy
def call(Map config = [:]) {
    boolean skipTests = config.get('skipTests', false)
    stage('Unit Tests') {
        if (!skipTests) {
            sh 'mvn test'
        }
    }
    stage('Package Application') {
        sh "mvn clean package -DskipTests=${skipTests}"
    }
}
```

### 2. `shared-library/vars/buildImage.groovy`
```groovy
def call(Map config = [:]) {
    String fullImage     = "${config.imageName}:${config.imageTag}"
    String credentialsId = config.credentialsId ?: 'dockerhub-credentials'

    stage('Build Docker Image') {
        sh "docker build -t ${fullImage} ."
    }
    stage('Scan Docker Image') {
        sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${fullImage}"
    }
    stage('Push Image to DockerHub') {
        withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
            sh "docker push ${fullImage}"
        }
    }
    stage('Delete Local Image') {
        sh "docker rmi ${fullImage} || true"
    }
}
```

### 3. `shared-library/vars/deployOnK8s.groovy`
```groovy
def call(Map config = [:]) {
    String manifestPath = config.manifestPath ?: 'k8s/deployment.yaml'
    String fullImage    = config.fullImage
    String namespace    = config.namespace ?: 'ivolve'

    stage('Edit Deployment File') {
        sh "sed -i.bak -E 's|image: .*/demoapp:.*|image: ${fullImage}|g' ${manifestPath}"
    }
    stage('Deploy to Kubernetes Cluster') {
        sh "kubectl apply -f ${manifestPath} -n ${namespace}"
        sh "kubectl rollout status deployment/demo-app -n ${namespace} --timeout=120s"
    }
}
```

---

## 🛠️ Step-by-Step Jenkins Configuration

### 1. Register Shared Library in Jenkins
1. Go to **Dashboard** -> **Manage Jenkins** -> **System**.
2. Scroll to **Global Pipeline Libraries** and click **Add**:
   - **Name**: `ivolve-shared-library`
   - **Default version**: `main`
   - **Retrieval method**: Modern SCM -> Git -> Repository URL: `https://github.com/zeyadmvtr/Ivolve.git`
3. Click **Save**.

### 2. Configure Slave Node in Jenkins
1. Go to **Manage Jenkins** -> **Nodes** -> **New Node**:
   - Node name: `slave-node`
   - Type: Permanent Agent
2. Configure settings:
   - **Remote root directory**: `/home/jenkins`
   - **Labels**: `slave-node`
   - **Usage**: Only build jobs with label expressions matching this node
   - **Launch method**: Launch agent via SSH or Inbound Agent
3. Click **Save**.

---

## ⚡ Automated Execution

```bash
# 1. Start Jenkins Slave Agent Container
bash scripts/01-setup-agent.sh

# 2. Verify Shared Library Modules
bash scripts/02-test-shared-libraries.sh
```
