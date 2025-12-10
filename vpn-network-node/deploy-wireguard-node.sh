#!/bin/bash
set -e

# Déploie un noeud WireGuard (VPN site du RER) dans un conteneur Docker.
# La configuration est générée per-université via universities/render_configs.sh
# Les overrides locaux vont dans wireguard.local.env

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

echo "Si les réseaux ne sont pas créés, lancez le script init-networks.sh"

COMPOSE_FILE="${SCRIPT_DIR}/wireguard-compose.yml"
# per-university generated env
UNIV_ENV_FILE="${SCRIPT_DIR}/wireguard.univ.env"
# local overrides
LOCAL_ENV_FILE="${SCRIPT_DIR}/wireguard.local.env"
RENDER_SCRIPT="${SCRIPT_DIR}/../universities/render_configs.sh"

# If a university short name is provided as first arg, generate per-university env
if [ $# -ge 1 ] && [ -n "$1" ]; then
  UNIV="$1"
  if [ -x "${RENDER_SCRIPT}" ]; then
    echo "Génération des fichiers env pour l'université '${UNIV}' via ${RENDER_SCRIPT}..."
    "${RENDER_SCRIPT}" "${UNIV}" || { echo "Erreur lors du rendu des configs pour ${UNIV}"; exit 1; }
  else
    echo "Renderer introuvable ou non exécutable: ${RENDER_SCRIPT}. Vous pouvez générer manuellement." >&2
  fi
fi

# Ensure per-university env exists
if [ ! -f "${UNIV_ENV_FILE}" ]; then
  echo "Attention: ${UNIV_ENV_FILE} introuvable. Vous pouvez générer avec universities/render_configs.sh <UNIV>."
fi

# Ensure local env exists: copy example if absent
if [ ! -f "${LOCAL_ENV_FILE}" ]; then
  EXAMPLE_FILE="${SCRIPT_DIR}/env-ex/wireguard.local.env.example"
  if [ -f "${EXAMPLE_FILE}" ]; then
    echo "Création de ${LOCAL_ENV_FILE} à partir de l'exemple..."
    cp "${EXAMPLE_FILE}" "${LOCAL_ENV_FILE}"
    echo "Vérifiez ${LOCAL_ENV_FILE} puis relancez si nécessaire."
  elif [ -f "${SCRIPT_DIR}/wireguard.local.env.example" ]; then
    echo "Création de ${LOCAL_ENV_FILE} à partir de l'exemple..."
    cp "${SCRIPT_DIR}/wireguard.local.env.example" "${LOCAL_ENV_FILE}"
    echo "Vérifiez ${LOCAL_ENV_FILE} puis relancez si nécessaire."
  else
    echo "Aucun fichier local d'exemple trouvé (${SCRIPT_DIR}/env-ex/wireguard.local.env.example ou ${SCRIPT_DIR}/wireguard.local.env.example)." >&2
  fi
fi

mkdir -p "${SCRIPT_DIR}/vpn"

echo "Démarrage du noeud WireGuard avec ${COMPOSE_FILE}..."

# Create .env for docker compose (read automatically for variable substitution)
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

docker compose -f "${COMPOSE_FILE}" up -d wireguard-node

echo "Noeud WireGuard démarré."
echo ""
echo "Paramètres per-université (wireguard.univ.env) :"
if [ -f "${UNIV_ENV_FILE}" ]; then
  grep -v '^#' "${UNIV_ENV_FILE}" | sed '/^$/d' || true
else
  echo "  (fichier ${UNIV_ENV_FILE} absent)"
fi
echo ""
echo "Paramètres locaux (wireguard.local.env) :"
if [ -f "${LOCAL_ENV_FILE}" ]; then
  grep -v '^#' "${LOCAL_ENV_FILE}" | sed '/^$/d' || true
else
  echo "  (fichier ${LOCAL_ENV_FILE} absent)"
fi

echo ""
echo "Les fichiers de configuration générés (wg0.conf, peers) sont dans ${SCRIPT_DIR}/vpn/config"
echo "Tu peux récupérer les fichiers/QR codes clients pour les postes distants."
