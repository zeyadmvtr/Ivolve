#!/usr/bin/env groovy

/**
 * Shared Library: DeployOnK8s
 * Modifies Kubernetes deployment manifest with the updated image tag
 * and applies resources to target cluster/namespace.
 *
 * @param config Map containing parameters:
 *               - manifestPath: String (path to deployment.yaml)
 *               - fullImage:    String (e.g. 'zeyadmvtr/demoapp:15')
 *               - namespace:    String (Kubernetes namespace, e.g. 'ivolve')
 */
def call(Map config = [:]) {
    String manifestPath = config.manifestPath ?: 'k8s/deployment.yaml'
    String fullImage    = config.fullImage ?: error("[DeployOnK8s] 'fullImage' is required!")
    String namespace    = config.namespace ?: 'ivolve'

    echo "=========================================================="
    echo ">>> [Shared Library: DeployOnK8s] Deploying ${fullImage} to ${namespace}"
    echo "=========================================================="

    stage('Edit Deployment File') {
        echo ">>> Updating image in manifest: ${manifestPath}..."
        sh """
            sed -i.bak -E "s|image: .*/demoapp:.*|image: ${fullImage}|g" ${manifestPath}
            grep "image:" ${manifestPath}
        """
        echo ">>> Manifest updated successfully with ${fullImage}."
    }

    stage('Deploy to Kubernetes Cluster') {
        echo ">>> Applying Kubernetes manifests to namespace '${namespace}'..."
        sh """
            kubectl apply -f ${manifestPath} -n ${namespace}
            if [ -f k8s/service.yaml ]; then
                kubectl apply -f k8s/service.yaml -n ${namespace}
            fi
            kubectl rollout status deployment/demo-app -n ${namespace} --timeout=120s
        """
        echo ">>> [DeployOnK8s] Application successfully rolled out to cluster!"
    }
}
