#!/usr/bin/env groovy

/**
 * Shared Library: BuildImage
 * Builds container image, scans for CVEs with Trivy, pushes to DockerHub,
 * and purges local container image from worker node.
 *
 * @param config Map containing required parameters:
 *               - imageName: String (e.g. 'zeyadmvtr/demoapp')
 *               - imageTag:  String (e.g. '12')
 *               - credentialsId: String (Jenkins credentials ID for DockerHub)
 */
def call(Map config = [:]) {
    String imageName     = config.imageName ?: error("[BuildImage] 'imageName' is required!")
    String imageTag      = config.imageTag ?: env.BUILD_NUMBER
    String fullImage     = "${imageName}:${imageTag}"
    String credentialsId = config.credentialsId ?: 'dockerhub-credentials'

    echo "=========================================================="
    echo ">>> [Shared Library: BuildImage] Image: ${fullImage}"
    echo "=========================================================="

    stage('Build Docker Image') {
        echo ">>> Executing docker build for ${fullImage}..."
        sh "docker build -t ${fullImage} ."
    }

    stage('Scan Docker Image') {
        echo ">>> Performing Trivy security vulnerability audit on ${fullImage}..."
        sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${fullImage}"
    }

    stage('Push Image to DockerHub') {
        echo ">>> Authenticating with Docker Hub using '${credentialsId}'..."
        withCredentials([usernamePassword(credentialsId: credentialsId, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
            sh "docker push ${fullImage}"
        }
        echo ">>> Successfully pushed ${fullImage} to Docker Hub!"
    }

    stage('Delete Local Image') {
        echo ">>> Purging local image ${fullImage} from agent host..."
        sh "docker rmi ${fullImage} || true"
        echo ">>> [BuildImage] Local image deleted cleanly."
    }
}
