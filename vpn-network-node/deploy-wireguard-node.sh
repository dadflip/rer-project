#!/bin/bash
set -e

# Déploie un noeud WireGuard (VPN site du RER) dans un conteneur Docker.
# La configuration est réglable via vpn/wireguard.env.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

echo "Si les réseaux ne sont pas créés, lancez le script init-networks.sh"

COMPOSE_FILE="${SCRIPT_DIR}/wireguard-compose.yml"
ENV_FILE="${SCRIPT_DIR}/wireguard.env"

# Création du fichier .env si absent
if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} introuvable."
  echo "Copie du template wireguard.env.example..."
  mkdir -p "${SCRIPT_DIR}/vpn"
  cp "${SCRIPT_DIR}/wireguard.env.example" "${ENV_FILE}"
  echo "Modifie ${ENV_FILE} si nécessaire puis relance ce script."
fi

echo "Démarrage du noeud WireGuard avec ${COMPOSE_FILE}..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d wireguard-node

echo "Noeud WireGuard démarré."
echo "Paramètres actuels :"
grep -v '^#' "${ENV_FILE}" | sed '/^$/d' || true

echo ""
echo "Les fichiers de configuration générés (wg0.conf, peers) sont dans ${SCRIPT_DIR}/vpn/config"
echo "Tu peux récupérer les fichiers/QR codes clients pour les postes distants."
