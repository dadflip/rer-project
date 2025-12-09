#!/bin/bash
set -e

# Déploie un cluster K3s dans le service docker-compose `k8s-master`
# puis applique les manifests pour un site donné (par défaut: utbm).

SITE="${1:-utbm}"
SITES_DIR="kubernetes/sites/${SITE}"
KUBECONFIG_FILE="./k3s/kubeconfig.yaml"

if [ ! -d "${SITES_DIR}" ]; then
  echo "Site inconnu: ${SITE}"
  echo "Dossiers disponibles dans kubernetes/sites/:"
  ls kubernetes/sites
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/deploy-postgres-node.sh"
"$SCRIPT_DIR/deploy-wireguard-node.sh"
"$SCRIPT_DIR/deploy-docker-local.sh"
"$SCRIPT_DIR/deploy-dnsdhcp-node.sh"

echo "▶️ Démarrage du master K3s dans Docker (service k8s-master)..."
docker compose up -d k8s-master

echo "⏳ Attente de la génération du kubeconfig..."
for i in {1..60}; do
  if [ -f "${KUBECONFIG_FILE}" ]; then
    break
  fi
  sleep 2
done

if [ ! -f "${KUBECONFIG_FILE}" ]; then
  echo "❌ kubeconfig non trouvé dans ${KUBECONFIG_FILE}"
  exit 1
fi

export KUBECONFIG="${KUBECONFIG_FILE}"

echo "✅ K3s prêt. Contexte courant:"
kubectl cluster-info

echo "▶️ Déploiement du site ${SITE}..."

kubectl apply -f "${SITES_DIR}/namespace.yaml"
kubectl apply -f "${SITES_DIR}/configmap.yaml"
kubectl apply -f "${SITES_DIR}/secrets.yaml"

NAMESPACE="rer-${SITE}"

kubectl apply -n "${NAMESPACE}" -f kubernetes/redis/
kubectl apply -n "${NAMESPACE}" -f kubernetes/backend/
kubectl apply -n "${NAMESPACE}" -f kubernetes/frontend/

kubectl apply -f "${SITES_DIR}/ingress.yaml" || true

echo "⏳ Attente de la disponibilité des pods dans ${NAMESPACE}..."
kubectl wait --for=condition=available deployment -n "${NAMESPACE}" --all --timeout=300s

echo "✅ Déploiement terminé pour le site ${SITE}."
echo "   Utilise le kubeconfig: ${KUBECONFIG_FILE}"


