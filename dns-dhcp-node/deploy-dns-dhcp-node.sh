#!/bin/bash
set -e

# Déploie le noeud DNS/DHCP avec Docker
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/dns-dhcp-compose.yml"
ENV_FILE="${SCRIPT_DIR}/dns-dhcp.env"
CONF_DNS_FILE="${SCRIPT_DIR}/dns/config/dnsmasq.conf"
CONF_DHCP_FILE="${SCRIPT_DIR}/dhcp/config/dnsmasq.conf"
CONFIGURE_SCRIPT="${SCRIPT_DIR}/configure"

# Création du fichier .env si absent
if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} introuvable."
  echo "Copie du template dns-dhcp.env.example..."
  mkdir -p "${SCRIPT_DIR}/dns" "${SCRIPT_DIR}/dhcp"
  cp "${SCRIPT_DIR}/dns-dhcp.env.example" "${ENV_FILE}"
  echo "Modifie ${ENV_FILE} si nécessaire puis relance ce script."
fi

# Exécution du script configure pour générer les fichiers dnsmasq
if [ -x "${CONFIGURE_SCRIPT}" ]; then
  echo "Génération des fichiers de configuration DNS/DHCP..."
  "${CONFIGURE_SCRIPT}" || { echo "Erreur lors de l'exécution de configure"; exit 1; }
else
  echo "Le script configure n'est pas exécutable ou introuvable : ${CONFIGURE_SCRIPT}"
  exit 1
fi

# Lancement des conteneurs
echo "Démarrage des noeuds DNS et DHCP..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d dns-node dhcp-node

echo "Noeuds DNS et DHCP démarrés."
echo ""
echo "Paramètres actuels (dns-dhcp.env) :"
grep -v '^#' "${ENV_FILE}" | sed '/^$/d' || true
echo ""
echo "Configuration DNS : ${CONF_DNS_FILE}"
echo "Configuration DHCP : ${CONF_DHCP_FILE}"
