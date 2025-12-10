#!/bin/bash
set -e

# Déploie le noeud DNS/DHCP avec Docker
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/dns-dhcp-compose.yml"
# per-university generated env (created by universities/render_configs.sh)
UNIV_ENV_FILE="${SCRIPT_DIR}/dns-dhcp.univ.env"
# local overrides maintained by the operator
LOCAL_ENV_FILE="${SCRIPT_DIR}/dns-dhcp.local.env"
CONF_DNS_FILE="${SCRIPT_DIR}/dns/config/dnsmasq.conf"
CONF_DHCP_FILE="${SCRIPT_DIR}/dhcp/config/dnsmasq.conf"
CONFIGURE_SCRIPT="${SCRIPT_DIR}/configure"
RENDER_SCRIPT="${SCRIPT_DIR}/../universities/render_configs.sh"

# If a university short name is provided as first arg, generate per-university env
if [ $# -ge 1 ] && [ -n "$1" ]; then
  UNIV="$1"
  if [ -x "${RENDER_SCRIPT}" ]; then
    echo "Génération des fichiers env pour l'université '${UNIV}' via ${RENDER_SCRIPT}..."
    # call renderer from its location
    "${RENDER_SCRIPT}" "${UNIV}" || { echo "Erreur lors du rendu des configs pour ${UNIV}"; exit 1; }
  else
    echo "Renderer introuvable ou non exécutable: ${RENDER_SCRIPT}. Vous pouvez générer manuellement." >&2
  fi
fi

# Ensure per-university env exists (may be created by the renderer)
if [ ! -f "${UNIV_ENV_FILE}" ]; then
  echo "Attention: ${UNIV_ENV_FILE} introuvable. Vous pouvez générer avec universities/render_configs.sh <UNIV>."
fi

# Ensure local env exists: copy example if absent
if [ ! -f "${LOCAL_ENV_FILE}" ]; then
  EXAMPLE_FILE="${SCRIPT_DIR}/env-ex/dns-dhcp.local.env.example"
  if [ -f "${EXAMPLE_FILE}" ]; then
    echo "Création de ${LOCAL_ENV_FILE} à partir de l'exemple..."
    cp "${EXAMPLE_FILE}" "${LOCAL_ENV_FILE}"
    echo "Vérifiez ${LOCAL_ENV_FILE} puis relancez si nécessaire."
  elif [ -f "${SCRIPT_DIR}/dns-dhcp.local.env.example" ]; then
    echo "Création de ${LOCAL_ENV_FILE} à partir de l'exemple..."
    cp "${SCRIPT_DIR}/dns-dhcp.local.env.example" "${LOCAL_ENV_FILE}"
    echo "Vérifiez ${LOCAL_ENV_FILE} puis relancez si nécessaire."
  else
    echo "Aucun fichier local d'exemple trouvé (${SCRIPT_DIR}/env-ex/dns-dhcp.local.env.example ou ${SCRIPT_DIR}/dns-dhcp.local.env.example)." >&2
  fi
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
echo "Démarrage des noeuds DNS et DHCP (compose lit les deux fichiers env déclarés dans le compose)..."

# Créer un .env pour docker compose (lit automatiquement par docker compose pour substitution)
# Agrège les deux fichiers pour que docker compose fasse la substitution des variables
COMPOSE_ENV="${SCRIPT_DIR}/.env"
: > "${COMPOSE_ENV}"
if [ -f "${UNIV_ENV_FILE}" ]; then
  cat "${UNIV_ENV_FILE}" >> "${COMPOSE_ENV}"
fi
if [ -f "${LOCAL_ENV_FILE}" ]; then
  grep -v '^#' "${LOCAL_ENV_FILE}" | grep -v '^$' >> "${COMPOSE_ENV}" || true
fi

# Extract university name and set network names
if [ -f "${UNIV_ENV_FILE}" ]; then
  UNIV_SHORT=$(grep '^SHORT_NAME=' "${UNIV_ENV_FILE}" | cut -d= -f2 || echo "")
  if [ -n "$UNIV_SHORT" ]; then
    echo "LAN_NETWORK_NAME=lan-local-${UNIV_SHORT,,}" >> "${COMPOSE_ENV}"
    echo "VPN_NETWORK_NAME=vpn-net-${UNIV_SHORT,,}" >> "${COMPOSE_ENV}"
  fi
fi

docker compose -f "${COMPOSE_FILE}" up -d dns-node dhcp-node

echo "Noeuds DNS et DHCP démarrés."
echo ""
echo "Paramètres per-université (dns-dhcp.univ.env) :"
if [ -f "${UNIV_ENV_FILE}" ]; then
  grep -v '^#' "${UNIV_ENV_FILE}" | sed '/^$/d' || true
else
  echo "  (fichier ${UNIV_ENV_FILE} absent)"
fi
echo "Paramètres locaux (dns-dhcp.local.env) :"
if [ -f "${LOCAL_ENV_FILE}" ]; then
  grep -v '^#' "${LOCAL_ENV_FILE}" | sed '/^$/d' || true
else
  echo "  (fichier ${LOCAL_ENV_FILE} absent)"
fi
echo ""
echo "Configuration DNS : ${CONF_DNS_FILE}"
echo "Configuration DHCP : ${CONF_DHCP_FILE}"
