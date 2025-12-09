#!/bin/bash
set -e

# Interface physique du LAN (adapter à ton host)
PHYS_IFACE="eth0"

# Bloc entier de l'université (pour planification IP Docker interne)
UNIV_BLOCK="10.10.0.0/16"

# Sous-réseaux VLSM selon plan UTBM
LAN_SUBNET="10.10.0.0/19"        # LAN principal, 5000 hôtes
VPN_SUBNET="10.10.32.0/26"       # VPN site, 50 hôtes
DNS_IP="10.10.33.1/32"
DHCP_IP="10.10.33.2/32"
DB_IP="10.10.33.3/32"
REDIS_IP="10.10.33.4/32"
API_SUBNET="10.10.33.4/30"       # 2 IP pour API internes

# Réseaux Docker internes pour les autres services (API, DB, Redis, VPN)
LOCAL_BRIDGE_NAME="lan-local"

if ! docker network inspect $LOCAL_BRIDGE_NAME >/dev/null 2>&1; then
  echo "Création du réseau bridge Docker interne $LOCAL_BRIDGE_NAME..."
  docker network create \
    --driver bridge \
    --subnet $UNIV_BLOCK \
    $LOCAL_BRIDGE_NAME
else
  echo "Bridge Docker $LOCAL_BRIDGE_NAME existe déjà."
fi

echo "Réseaux Docker initialisés :"
docker network ls | grep -E "$LOCAL_BRIDGE_NAME"

# Affichage des IP utilisées pour services internes
echo ""
echo "Plan d'adressage interne :"
echo "Bloc université: $UNIV_BLOCK"
echo "LAN principal: $LAN_SUBNET"
echo "VPN: $VPN_SUBNET"
echo "DNS: $DNS_IP"
echo "DHCP: $DHCP_IP"
echo "DB: $DB_IP"
echo "Redis: $REDIS_IP"
echo "API internes: $API_SUBNET"
