#!/bin/bash

echo "🔻 Shutting down VM 2..."
echo "⚠️  This will stop roach-1 container"

docker compose -f docker-compose-vm2.yml down --remove-orphans --volumes

echo "✅ VM 2 shutdown complete!"
echo ""
echo "📊 Remaining containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 