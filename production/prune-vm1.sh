#!/bin/bash

echo "🧹 Cleaning up VM 1 Docker resources..."
echo "⚠️  This will remove stopped containers, unused networks, images, and volumes"
echo ""

# First, ensure containers are stopped
echo "🔻 Ensuring VM 1 containers are stopped..."
docker compose -f docker-compose-vm1.yml down --remove-orphans --volumes

echo ""
echo "🗑️  Pruning Docker system..."
docker system prune -a -f --volumes

echo ""
echo "📊 Docker system status after cleanup:"
echo "Images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
echo ""
echo "Volumes:"
docker volume ls
echo ""
echo "Networks:"
docker network ls

echo ""
echo "✅ VM 1 cleanup complete!" 