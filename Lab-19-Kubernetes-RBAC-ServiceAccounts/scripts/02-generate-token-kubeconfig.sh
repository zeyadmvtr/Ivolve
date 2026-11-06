#!/usr/bin/env bash
# ==============================================================================
# Script: 02-generate-token-kubeconfig.sh
# Purpose: Extract token for jenkinsSA and generate dedicated Jenkins kubeconfig
# Target: Run on Control Plane or any host with kubectl configured
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo ">>> Method A: Ephemeral Token via 'kubectl create token'"
echo "=========================================================="
EPHEMERAL_TOKEN=$(kubectl create token jenkinsSA -n ivolve --duration=24h)
echo "Ephemeral Token (24h valid):"
echo "${EPHEMERAL_TOKEN:0:35}..."

echo ""
echo "=========================================================="
echo ">>> Method B: Long-Lived Token from Secret 'jenkins-sa-token'"
echo "=========================================================="
LONG_LIVED_TOKEN=$(kubectl get secret jenkins-sa-token -n ivolve -o jsonpath='{.data.token}' | base64 --decode)
echo "Long-Lived Token extracted from Secret:"
echo "${LONG_LIVED_TOKEN:0:35}..."

echo ""
echo "=========================================================="
echo ">>> Step 3: Generating Jenkins Kubeconfig (jenkins-kubeconfig.yaml)"
echo "=========================================================="
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='${CURRENT_CONTEXT}')].context.cluster}")
SERVER_URL=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${CLUSTER_NAME}')].cluster.server}")
CA_DATA=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name=='${CLUSTER_NAME}')].cluster.certificate-authority-data}")

cat <<EOF > jenkins-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_DATA}
    server: ${SERVER_URL}
  name: ${CLUSTER_NAME}
users:
- name: jenkinsSA
  user:
    token: ${LONG_LIVED_TOKEN}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ivolve
    user: jenkinsSA
  name: jenkins-ivolve-context
current-context: jenkins-ivolve-context
EOF

echo "[+] File 'jenkins-kubeconfig.yaml' successfully created!"
echo "    Can be mounted into Jenkins CI/CD pipelines."
