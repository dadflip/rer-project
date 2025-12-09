#!/bin/bash
set -e

# Build (et optionnellement push) les images backend et frontend
# Utilise la variable d'environnement REGISTRY (ex: REGISTRY=my-registry.com)

REGISTRY="${REGISTRY:-}"
TAG="${TAG:-latest}"

if [ -z "${REGISTRY}" ]; then
  echo "⚠️  REGISTRY n'est pas défini."
  echo "Les images seront taguées localement sans push."
  IMAGE_BACKEND="rer-backend:${TAG}"
  IMAGE_FRONTEND="rer-frontend:${TAG}"
else
  IMAGE_BACKEND="${REGISTRY}/rer-backend:${TAG}"
  IMAGE_FRONTEND="${REGISTRY}/rer-frontend:${TAG}"
fi

echo "▶️ Build backend → ${IMAGE_BACKEND}"
docker build -t "${IMAGE_BACKEND}" ./backend

echo "▶️ Build frontend → ${IMAGE_FRONTEND}"
docker build -t "${IMAGE_FRONTEND}" ./frontend

if [ -n "${REGISTRY}" ]; then
  echo "▶️ Push vers le registry ${REGISTRY}..."
  docker push "${IMAGE_BACKEND}"
  docker push "${IMAGE_FRONTEND}"
fi

echo "✅ Images construites."


