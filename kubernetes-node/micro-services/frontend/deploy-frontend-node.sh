#!/usr/bin/env bash
set -euo pipefail

# Frontend Node Deployment Script
# Deploys the RER Frontend service with environment configuration

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FRONTEND_DIR="$ROOT/kubernetes-node/micro-services/frontend"

echo "Deploying Frontend Node..."

# Ensure .env files exist
UNIV_ENV="$FRONTEND_DIR/frontend.univ.env"
LOCAL_ENV="$FRONTEND_DIR/frontend.local.env"

if [ ! -f "$UNIV_ENV" ]; then
  echo "Error: $UNIV_ENV not found" >&2
  exit 1
fi

if [ ! -f "$LOCAL_ENV" ]; then
  echo "Warning: $LOCAL_ENV not found, creating from example..."
  if [ -f "$FRONTEND_DIR/../../env-ex/frontend.local.env.example" ]; then
    cp "$FRONTEND_DIR/../../env-ex/frontend.local.env.example" "$LOCAL_ENV"
  else
    echo "Error: Example local env not found" >&2
    exit 1
  fi
fi

# Create aggregated .env for Docker Compose
COMPOSE_ENV="$FRONTEND_DIR/.env"
cat "$UNIV_ENV" > "$COMPOSE_ENV"
if [ -f "$LOCAL_ENV" ]; then
  cat "$LOCAL_ENV" >> "$COMPOSE_ENV"
fi

# Extract university name and set network names
if [ -f "$UNIV_ENV" ]; then
  UNIV_SHORT=$(grep '^SHORT_NAME=' "$UNIV_ENV" | cut -d= -f2 || echo "")
  if [ -n "$UNIV_SHORT" ]; then
    echo "LAN_NETWORK_NAME=lan-local-${UNIV_SHORT,,}" >> "$COMPOSE_ENV"
    echo "VPN_NETWORK_NAME=vpn-net-${UNIV_SHORT,,}" >> "$COMPOSE_ENV"
  fi
fi

# Load environment for defaults
source "$UNIV_ENV"
if [ -f "$LOCAL_ENV" ]; then
  source "$LOCAL_ENV"
fi

# Deploy with Docker Compose
cd "$FRONTEND_DIR"
docker compose -f docker-compose.yml up -d

echo "Frontend Node deployed successfully"
