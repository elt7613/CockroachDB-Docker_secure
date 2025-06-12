#!/bin/bash

echo "🔻 Shutting down VM 3..."
echo "⚠️  This will stop roach-2 container"

docker compose -f docker-compose-vm3.yml down --remove-orphans --volumes

echo "✅ VM 3 shutdown complete!"
echo ""
echo "📊 Remaining containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 