#!/bin/bash
set -e

echo "ATTENTION : Vous êtes sur le point de SUPPRIMER TOUTES les ressources Docker."
echo "   Cela inclut :"
echo "   - Tous les conteneurs (en cours + arrêtés)"
echo "   - Toutes les images"
echo "   - Tous les volumes (données PERDUES)"
echo "   - Tous les réseaux personnalisés"
echo ""
echo "Cette action est irréversible."
echo ""

read -p "Voulez-vous continuer ? (oui/non) : " confirm

if [[ "$confirm" != "oui" ]]; then
    echo "Opération annulée."
    exit 0
fi

echo "Arrêt de tous les conteneurs..."
docker ps -q | xargs -r docker stop

echo "Suppression de tous les conteneurs..."
docker ps -aq | xargs -r docker rm -f

echo "Suppression de toutes les images..."
docker images -aq | xargs -r docker rmi -f

echo "Suppression de tous les volumes..."
docker volume ls -q | xargs -r docker volume rm -f

echo "Suppression de tous les réseaux Docker (sauf les réseaux de base)..."
docker network ls --format '{{.ID}} {{.Name}}' | grep -vE "bridge|host|none" | awk '{print $1}' | xargs -r docker network rm

echo "Nettoyage complet terminé !"
