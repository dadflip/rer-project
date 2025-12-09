#!/bin/bash

# Root folder
PROJECT="rer-k8s-project"
mkdir -p $PROJECT

echo "📁 Creating project structure: $PROJECT"

########################
# BACKEND (Django)
########################
mkdir -p $PROJECT/backend/{config,documents,users}

touch $PROJECT/backend/Dockerfile
touch $PROJECT/backend/requirements.txt
touch $PROJECT/backend/manage.py

# Django config files
touch $PROJECT/backend/config/settings.py
touch $PROJECT/backend/config/urls.py
touch $PROJECT/backend/config/wsgi.py

# Documents app
touch $PROJECT/backend/documents/models.py
touch $PROJECT/backend/documents/serializers.py
touch $PROJECT/backend/documents/views.py
touch $PROJECT/backend/documents/urls.py

# Users app
touch $PROJECT/backend/users/models.py
touch $PROJECT/backend/users/serializers.py
touch $PROJECT/backend/users/views.py

########################
# FRONTEND (Node.js)
########################
mkdir -p $PROJECT/frontend/public

touch $PROJECT/frontend/Dockerfile
touch $PROJECT/frontend/package.json
touch $PROJECT/frontend/server.js

touch $PROJECT/frontend/public/index.html
touch $PROJECT/frontend/public/app.js
touch $PROJECT/frontend/public/styles.css

########################
# KUBERNETES MANIFESTS
########################
mkdir -p $PROJECT/kubernetes/{database,redis,backend,frontend,ingress,vpn}

touch $PROJECT/kubernetes/namespace.yaml
touch $PROJECT/kubernetes/configmap.yaml
touch $PROJECT/kubernetes/secrets.yaml

# Postgres
touch $PROJECT/kubernetes/database/postgres-statefulset.yaml
touch $PROJECT/kubernetes/database/postgres-service.yaml
touch $PROJECT/kubernetes/database/postgres-pvc.yaml

# Redis
touch $PROJECT/kubernetes/redis/redis-deployment.yaml
touch $PROJECT/kubernetes/redis/redis-service.yaml

# Backend Django
touch $PROJECT/kubernetes/backend/django-deployment.yaml
touch $PROJECT/kubernetes/backend/django-service.yaml

# Frontend
touch $PROJECT/kubernetes/frontend/frontend-deployment.yaml
touch $PROJECT/kubernetes/frontend/frontend-service.yaml

# Ingress
touch $PROJECT/kubernetes/ingress/ingress.yaml

# VPN WireGuard
touch $PROJECT/kubernetes/vpn/wireguard-daemonset.yaml
touch $PROJECT/kubernetes/vpn/wireguard-configmap.yaml

########################
# SCRIPTS
########################
mkdir -p $PROJECT/scripts

touch $PROJECT/scripts/deploy.sh
touch $PROJECT/scripts/init-db.sh
touch $PROJECT/scripts/backup.sh

########################
# DOCKER COMPOSE (local dev)
########################
touch $PROJECT/docker-compose.yml

echo "✅ Architecture created successfully!"
