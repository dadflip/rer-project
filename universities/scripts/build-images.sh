#!/bin/bash
set -e

# Build (et optionnellement push) les images backend et frontend
# Utilise la variable d'environnement REGISTRY (ex: REGISTRY=my-registry.com)

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND_DIR="$ROOT/kubernetes-node/micro-services/backend"
FRONTEND_DIR="$ROOT/kubernetes-node/micro-services/frontend"

REGISTRY="${REGISTRY:-}"
TAG="${TAG:-latest}"

if [ ! -d "$BACKEND_DIR" ] || [ ! -d "$FRONTEND_DIR" ]; then
  echo "Error: Backend or Frontend source directory not found"
  echo "  Backend: $BACKEND_DIR"
  echo "  Frontend: $FRONTEND_DIR"
  exit 1
fi

if [ -z "${REGISTRY}" ]; then
  echo "REGISTRY not defined."
  echo "Images will be tagged locally without push."
  IMAGE_BACKEND="backend-backend:${TAG}"
  IMAGE_FRONTEND="frontend-frontend:${TAG}"
else
  IMAGE_BACKEND="${REGISTRY}/backend-backend:${TAG}"
  IMAGE_FRONTEND="${REGISTRY}/frontend-frontend:${TAG}"
fi

echo "Building backend → ${IMAGE_BACKEND}"
docker build -t "${IMAGE_BACKEND}" "$BACKEND_DIR"

echo "Building frontend → ${IMAGE_FRONTEND}"
docker build -t "${IMAGE_FRONTEND}" "$FRONTEND_DIR"

if [ -n "${REGISTRY}" ]; then
  echo "Pushing to registry ${REGISTRY}..."
  docker push "${IMAGE_BACKEND}"
  docker push "${IMAGE_FRONTEND}"
fi

echo "Images built successfully."


