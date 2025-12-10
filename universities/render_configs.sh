#!/usr/bin/env bash
set -euo pipefail

# RER Config Renderer
# Generates per-university config files from base defaults and university-specific configs
# Usage: ./render_configs.sh <UNIVERSITY>

if [ $# -lt 1 ]; then
  echo "Usage: $0 <UNIVERSITY>"
  echo ""
  echo "Generates *.univ.env files for the specified university"
  exit 1
fi

UNIV="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTDIR="$ROOT/universities"
CONFIGS_DIR="$SCRIPTDIR/configs"
DEFAULTS="$SCRIPTDIR/defaults.env"

# Load defaults
if [ ! -f "$DEFAULTS" ]; then
  echo "Error: Defaults file not found: $DEFAULTS" >&2
  exit 1
fi
source "$DEFAULTS"

# Load university config
CONF="${CONFIGS_DIR}/${UNIV}.env"
if [ ! -f "$CONF" ]; then
  echo "Error: University config not found: $CONF" >&2
  echo "Available universities: $(ls "$CONFIGS_DIR" | sed -e 's/\.env$//g')"
  exit 2
fi
source "$CONF"

# Helper function to write env file
write_env() {
  local file="$1"
  shift
  {
    for var in "$@"; do
      eval "val=\$$var"
      echo "$var=$val"
    done
  } > "$file"
}

# Extract IPs from BASE_CIDR
IFS='/' read -r BASE_IP BASE_PREFIX <<< "$BASE_CIDR"
IFS='.' read -r A B C D <<< "$BASE_IP"

#############################################
# NEW VLSM PLAN (updated to your requirements)
#############################################

# LAN principal /19  → 10.10.0.0–10.10.31.255
LAN_SUBNET="${A}.${B}.0.0/19"

# VPN /26  → 10.10.32.0–10.10.32.63
VPN_SUBNET="${A}.${B}.32.0/26"

#############################################
# SERVICE IPs placed INSIDE the main LAN
#############################################

IP_DNS_NODE="${A}.${B}.0.10"
IP_DHCP_NODE="${A}.${B}.0.11"
IP_POSTGRES_NODE="${A}.${B}.0.12"
IP_REDIS_NODE="${A}.${B}.0.13"
IP_BACKEND_NODE="${A}.${B}.0.14"
IP_FRONTEND_NODE="${A}.${B}.0.15"

# WireGuard
IP_WG_LAN="${A}.${B}.0.16"    # LAN side
IP_WG_VPN="${A}.${B}.32.16"    # VPN side

#############################################

# Generate DNS/DHCP config
DNS_DHCP_ENV="$ROOT/dns-dhcp-node/dns-dhcp.univ.env"
write_env "$DNS_DHCP_ENV" \
  BASE_CIDR \
  LAN_SUBNET \
  IP_DNS_NODE \
  IP_DHCP_NODE \
  UPSTREAM_DNS1 \
  UPSTREAM_DNS2 \
  LOCAL_DOMAIN

echo "Generated: $DNS_DHCP_ENV"

# Generate Postgres config
POSTGRES_ENV="$ROOT/postgres-node/postgres.univ.env"
write_env "$POSTGRES_ENV" \
  BASE_CIDR \
  LAN_SUBNET \
  IP_POSTGRES_NODE \
  POSTGRES_DB \
  POSTGRES_USER

echo "Generated: $POSTGRES_ENV"

# Generate Wireguard config
WIREGUARD_ENV="$ROOT/vpn-network-node/wireguard.univ.env"
{
  echo "BASE_CIDR=$BASE_CIDR"
  echo "LAN_SUBNET=$LAN_SUBNET"
  echo "VPN_SUBNET=$VPN_SUBNET"
  echo "IP_WG_LAN=$IP_WG_LAN"
  echo "IP_WG_VPN=$IP_WG_VPN"
  echo "SERVERPORT=${SERVERPORT:-51820}"
  echo "PEERS=${PEERS:-0}"
  echo "PEERDNS=${PEERDNS:-1.1.1.1}"
  echo "INTERNAL_SUBNET=${VPN_SUBNET}"
} > "$WIREGUARD_ENV"

echo "Generated: $WIREGUARD_ENV"

# Generate Backend config
BACKEND_ENV="$ROOT/kubernetes-node/micro-services/backend/backend.univ.env"
{
  echo "BASE_CIDR=$BASE_CIDR"
  echo "LAN_SUBNET=$LAN_SUBNET"
  echo "IP_BACKEND_NODE=$IP_BACKEND_NODE"
  echo "POSTGRES_DB=${POSTGRES_DB:-rerdb}"
  echo "POSTGRES_USER=${POSTGRES_USER:-reruser}"
  echo "API_PORT=${API_PORT:-8000}"
} > "$BACKEND_ENV"

echo "Generated: $BACKEND_ENV"

# Generate Frontend config
FRONTEND_ENV="$ROOT/kubernetes-node/micro-services/frontend/frontend.univ.env"
{
  echo "BASE_CIDR=$BASE_CIDR"
  echo "LAN_SUBNET=$LAN_SUBNET"
  echo "IP_FRONTEND_NODE=$IP_FRONTEND_NODE"
  echo "REACT_APP_API_URL=http://${IP_BACKEND_NODE}:8000/api"
  echo "FRONTEND_PORT=${FRONTEND_PORT:-3000}"
} > "$FRONTEND_ENV"

echo "Generated: $FRONTEND_ENV"

echo ""
echo "All config files generated successfully for $UNIV"
