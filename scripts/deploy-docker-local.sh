#!/bin/bash
set -e

# Lance l'environnement local complet via docker-compose (sans Kubernetes)
# - postgres
# - redis
# - backend (Django)
# - frontend (Node.js)

echo "▶️ Build & start des microservices en local (docker-compose)..."
docker compose up -d postgres redis backend frontend

echo "✅ Services démarrés."
echo "   Backend API : http://localhost:8000/api/"
echo "   Frontend    : http://localhost:3000/"


