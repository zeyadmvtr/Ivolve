#!/usr/bin/env groovy

/**
 * Shared Library: DeployOnK8s (GitOps Edition for Lab 23)
 * Updates the deployment manifest with new image tag and PUSHES changes
 * back to the GitHub repository, triggering Argo CD automated sync.
 *
 * @param config Map containing parameters:
 *               - manifestPath: String (path to deployment.yaml)
 *               - fullImage:    String (e.g. 'zeyadmvtr/demoapp:25')
 *               - gitBranch:    String (e.g. 'main')
 *               - gitCredsId:   String (Jenkins credentials ID with push access)
 */
def call(Map config = [:]) {
    String manifestPath = config.manifestPath ?: 'Lab-23-GitOps-ArgoCD-and-Jenkins/manifests/app/deployment.yaml'
    String fullImage    = config.fullImage ?: error("[DeployOnK8s-GitOps] 'fullImage' is required!")
    String gitBranch    = config.gitBranch ?: 'main'
    String gitCredsId   = config.gitCredsId ?: 'github-pat-credentials'

    echo "=========================================================="
    echo ">>> [DeployOnK8s: GitOps] Updating Git Manifest & Pushing to GitHub"
    echo "=========================================================="

    stage('Edit Deployment File') {
        echo ">>> Modifying image tag to '${fullImage}' in ${manifestPath}..."
        sh """
            sed -i.bak -E "s|image: .*/demoapp:.*|image: ${fullImage}|g" ${manifestPath}
            grep "image:" ${manifestPath}
        """
        echo ">>> Manifest updated successfully with ${fullImage}."
    }

    stage('Push Updates to GitHub (GitOps Trigger)') {
        echo ">>> Committing and Pushing manifest change to branch '${gitBranch}'..."
        withCredentials([usernamePassword(credentialsId: gitCredsId, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
            sh """
                git config user.name "jenkins-bot"
                git config user.email "jenkins-bot@ivolve.local"
                git add ${manifestPath}
                git commit -m "ci(gitops): update application image to ${fullImage} [skip ci]" || echo "No changes to commit"
                
                # Push using authenticated remote URL
                git push https://\${GIT_TOKEN}@github.com/zeyadmvtr/Ivolve.git HEAD:${gitBranch}
            """
        }
        echo ">>> [DeployOnK8s: GitOps] Git commit pushed successfully!"
        echo ">>> Argo CD will automatically detect the commit and synchronize Kubernetes cluster."
    }
}
