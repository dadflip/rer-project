#!/bin/bash
set -e

# Déploie un noeud PostgreSQL dédié dans un conteneur Docker.
# La configuration est réglable via postgres.env.

echo "Si les réseaux ne sont pas créés, lancez le script init-networks.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/postgres-compose.yml"
ENV_FILE="${SCRIPT_DIR}/postgres.env"

# Création du fichier .env si absent
if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} introuvable."
  echo "Copie du template postgres.env.example..."
  cp "${SCRIPT_DIR}/postgres.env.example" "${ENV_FILE}"
  echo "Modifie ${ENV_FILE} si nécessaire puis relance ce script."
fi

echo "Démarrage du noeud PostgreSQL avec ${COMPOSE_FILE}..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d postgres-node

echo "Noeud PostgreSQL démarré."
echo "Paramètres actuels :"
grep -v '^#' "${ENV_FILE}" | sed '/^$/d' || true
