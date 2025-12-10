#!/usr/bin/env bash
set -euo pipefail

# RER Unified Launch Script
# Flexible deployment orchestrator for configuring, building, and deploying RER nodes
# Usage: ./universities/launch.sh [OPTIONS] <UNIVERSITY>
#
# FLAGS:
#   -h, --help                Show this help message
#   -n, --init-networks       Initialize Docker networks for the university
#   -g, --gen-univ-config     Generate per-university config files (*.univ.env)
#   -l, --gen-local-config    Generate local config templates (*.local.env)
#   -b, --build-images        Build Docker images (backend, frontend)
#   -d, --deploy-all          Deploy all nodes (DNS/DHCP, Postgres, Wireguard)
#   --deploy-dns              Deploy DNS/DHCP node only
#   --deploy-postgres         Deploy Postgres node only
#   --deploy-wireguard        Deploy Wireguard node only
#   -a, --all                 Run all steps: init-networks, gen configs, build, deploy
#   -c, --config-only         Generate configs only (gen-univ + gen-local)
#   --clean                   Clean all containers, images, volumes for the university
#   -r, --registry REGISTRY   Set Docker registry (for build-images)
#   -t, --tag TAG             Set image tag (default: latest)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTDIR="$ROOT/universities"
CONFIGS_DIR="$SCRIPTDIR/configs"
DEFAULTS="$SCRIPTDIR/defaults.env"

# Source defaults
# shellcheck source=/dev/null
source "$DEFAULTS"

# Flags
INIT_NETWORKS=0
GEN_UNIV_CONFIG=0
GEN_LOCAL_CONFIG=0
BUILD_IMAGES=0
DEPLOY_ALL=0
DEPLOY_DNS=0
DEPLOY_POSTGRES=0
DEPLOY_WIREGUARD=0
CLEAN=0
CLEAN_ALL=0
REGISTRY="${REGISTRY:-}"
TAG="${TAG:-latest}"

UNIV=""

usage() {
  grep "^#" "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
  echo ""
  echo "Available Universities:"
  if [ -d "$CONFIGS_DIR" ]; then
    ls "$CONFIGS_DIR" | sed -e 's/\.env$//g' | sed 's/^/  - /'
  else
    echo "  (configs directory not found)"
  fi
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 [OPTIONS] <UNIVERSITY>"
  echo ""
  usage
  exit 1
fi

# Quick check for --clean without university (clean all)
if [ "$1" = "--clean" ] && [ $# -eq 1 ]; then
  echo "Cleaning all Docker resources..."
  "$SCRIPTDIR/scripts/clean-docker.sh" || { echo "Error cleaning Docker resources"; exit 1; }
  echo "All Docker resources cleaned"
  exit 0
fi

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -n|--init-networks)
      INIT_NETWORKS=1
      shift
      ;;
    -g|--gen-univ-config)
      GEN_UNIV_CONFIG=1
      shift
      ;;
    -l|--gen-local-config)
      GEN_LOCAL_CONFIG=1
      shift
      ;;
    -b|--build-images)
      BUILD_IMAGES=1
      shift
      ;;
    -d|--deploy-all)
      DEPLOY_ALL=1
      DEPLOY_DNS=1
      DEPLOY_POSTGRES=1
      DEPLOY_WIREGUARD=1
      shift
      ;;
    --deploy-dns)
      DEPLOY_DNS=1
      shift
      ;;
    --deploy-postgres)
      DEPLOY_POSTGRES=1
      shift
      ;;
    --deploy-wireguard)
      DEPLOY_WIREGUARD=1
      shift
      ;;
    -a|--all)
      INIT_NETWORKS=1
      GEN_UNIV_CONFIG=1
      GEN_LOCAL_CONFIG=1
      BUILD_IMAGES=1
      DEPLOY_DNS=1
      DEPLOY_POSTGRES=1
      DEPLOY_WIREGUARD=1
      shift
      ;;
    -c|--config-only)
      GEN_UNIV_CONFIG=1
      GEN_LOCAL_CONFIG=1
      shift
      ;;
    -r|--registry)
      REGISTRY="$2"
      shift 2
      ;;
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    --clean)
      CLEAN=1
      shift
      ;;
    --clean-all)
      CLEAN_ALL=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [ -z "$UNIV" ]; then
        UNIV="$1"
      else
        echo "Multiple universities not supported" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Handle --clean-all (clean everything without university)
if [ $CLEAN_ALL -eq 1 ]; then
  echo "Cleaning all Docker resources..."
  docker ps -a --format '{{.Names}}' | grep -E '^(rer-|dns-|postgres-|wireguard-)' | xargs -r docker rm -f 2>/dev/null || true
  docker network ls --format '{{.Name}}' | grep -E '^(lan-local-|vpn-net-)' | xargs -r docker network rm 2>/dev/null || true
  echo "All Docker resources cleaned"
  exit 0
fi

if [ -z "$UNIV" ]; then
  echo "Error: No university specified" >&2
  exit 1
fi

CONF="${CONFIGS_DIR}/${UNIV}.env"
if [ ! -f "$CONF" ]; then
  echo "Error: Config $CONF not found" >&2
  echo "Available universities: $(ls "$CONFIGS_DIR" | sed -e 's/\.env$//g')"
  exit 2
fi

# Load university config
# shellcheck source=/dev/null
source "$CONF"

echo "========================================================"
echo "RER Deployment Orchestrator - University: ${UNIV}"
echo "========================================================"
echo ""

# Extract IPs from BASE_CIDR (used for network creation)
IFS='/' read -r BASE_IP BASE_PREFIX <<< "$BASE_CIDR"
IFS='.' read -r A B C D <<< "$BASE_IP"

# Network definitions derived from VLSM plan
UNIV_BLOCK="${A}.${B}.0.0/16"
LAN_SUBNET="${A}.${B}.0.0/19"
VPN_SUBNET="${A}.${B}.32.0/26"
LOCAL_BRIDGE_NAME="lan-local-${UNIV,,}"
VPN_NETWORK_NAME="vpn-net-${UNIV,,}"

# Step 0: Clean (if requested)
if [ $CLEAN -eq 1 ]; then
  echo "Step 0/5: Cleaning Docker resources for ${UNIV}..."
  "$SCRIPTDIR/scripts/clean-docker.sh" || { echo "Error cleaning Docker resources"; exit 1; }
  echo ""
fi

# Step 1: Initialize networks
if [ $INIT_NETWORKS -eq 1 ]; then
  echo "Step 1/5: Initializing Docker networks for ${UNIV}..."
  
  # Create bridge network lan-local if not exists
  if ! docker network inspect "lan-local" >/dev/null 2>&1; then
    echo "   Creating bridge network lan-local with subnet $LAN_SUBNET..."
    docker network create \
      --driver bridge \
      --subnet "$LAN_SUBNET" \
      lan-local
  else
    echo "   Bridge network lan-local already exists."
  fi

  # Create VPN network vpn-net if not exists
  if ! docker network inspect "vpn-net" >/dev/null 2>&1; then
    echo "   Creating VPN network vpn-net with subnet $VPN_SUBNET..."
    docker network create \
      --driver bridge \
      --subnet "$VPN_SUBNET" \
      vpn-net
  else
    echo "   VPN network vpn-net already exists."
  fi
  
  echo "   Networks initialized"
  echo ""
fi

# Step 2: Generate per-university config files
if [ $GEN_UNIV_CONFIG -eq 1 ]; then
  echo "Step 2/5: Generating per-university config files..."
  "$SCRIPTDIR/render_configs.sh" "$UNIV" || { echo "Error generating configs"; exit 1; }
  echo "   University configs generated"
  echo ""
fi

# Step 3: Generate local config templates
if [ $GEN_LOCAL_CONFIG -eq 1 ]; then
  echo "Step 3/5: Generating local config templates..."
  
  for node in dns-dhcp postgres wireguard backend frontend; do
    case "$node" in
      dns-dhcp)
        node_dir="$ROOT/dns-dhcp-node"
        ;;
      postgres)
        node_dir="$ROOT/postgres-node"
        ;;
      wireguard)
        node_dir="$ROOT/vpn-network-node"
        ;;
      backend)
        node_dir="$ROOT/kubernetes-node/micro-services/backend"
        ;;
      frontend)
        node_dir="$ROOT/kubernetes-node/micro-services/frontend"
        ;;
    esac
    
    if [ -d "$node_dir" ]; then
      local_env="$node_dir/${node}.local.env"
      if [ ! -f "$local_env" ]; then
        example="${node_dir}/../env-ex/${node}.local.env.example"
        if [ ! -f "$example" ]; then
          example="${node_dir}/env-ex/${node}.local.env.example"
        fi
        if [ -f "$example" ]; then
          echo "   Creating ${node}.local.env from example..."
          cp "$example" "$local_env"
        fi
      fi
    fi
  done
  
  echo "   Local config templates created"
  echo ""
fi

# Step 4: Build images
if [ $BUILD_IMAGES -eq 1 ]; then
  echo "Step 4/5: Building Docker images..."
  "$SCRIPTDIR/scripts/build-images.sh" || { echo "Error building images"; exit 1; }
  echo ""
fi

# Step 5: Deploy nodes
if [ $DEPLOY_DNS -eq 1 ] || [ $DEPLOY_POSTGRES -eq 1 ] || [ $DEPLOY_WIREGUARD -eq 1 ]; then
  echo "Step 5/5: Deploying nodes..."
  
  if [ $DEPLOY_DNS -eq 1 ]; then
    echo "   Deploying DNS/DHCP node..."
    "$ROOT/dns-dhcp-node/deploy-dns-dhcp-node.sh" || { echo "Error deploying DNS/DHCP"; exit 1; }
    echo ""
  fi
  
  if [ $DEPLOY_POSTGRES -eq 1 ]; then
    echo "   Deploying Postgres node..."
    "$ROOT/postgres-node/deploy-postgres-node.sh" || { echo "Error deploying Postgres"; exit 1; }
    echo ""
  fi
  
  if [ $DEPLOY_WIREGUARD -eq 1 ]; then
    echo "   Deploying Wireguard node..."
    "$ROOT/vpn-network-node/deploy-wireguard-node.sh" || { echo "Error deploying Wireguard"; exit 1; }
    echo ""
  fi
  
  if [ $DEPLOY_DNS -eq 1 ] || [ $DEPLOY_POSTGRES -eq 1 ] || [ $DEPLOY_WIREGUARD -eq 1 ]; then
    echo "   Deploying Backend node..."
    "$ROOT/kubernetes-node/micro-services/backend/deploy-backend-node.sh" || { echo "Error deploying Backend"; exit 1; }
    echo ""
    
    echo "   Deploying Frontend node..."
    "$ROOT/kubernetes-node/micro-services/frontend/deploy-frontend-node.sh" || { echo "Error deploying Frontend"; exit 1; }
    echo ""
  fi
  
  echo "   Nodes deployed"
  echo ""
fi

# Summary
echo "========================================================"
echo "Deployment complete for ${UNIV}"
echo "========================================================"
echo ""
echo "University: ${UNIV}"
echo "Block: ${UNIV_BLOCK}"
echo "LAN: ${LAN_SUBNET}"
echo "VPN: ${VPN_SUBNET}"
echo ""
echo "Next steps:"
echo "  - Check container logs: docker compose -f <node>/docker-compose.yml logs"
echo "  - Stop containers: docker compose -f <node>/docker-compose.yml down"
echo "  - Deploy another university: $0 -a <OTHER_UNIV>"
echo ""

exit 0