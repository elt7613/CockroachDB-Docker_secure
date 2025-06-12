#!/bin/bash

echo "🔻 Shutting down VM 1 (Bootstrap Node)..."
echo "⚠️  This will stop roach-0 and roach-init containers"

docker compose -f docker-compose-vm1.yml down --remove-orphans --volumes

echo "✅ VM 1 shutdown complete!"
echo ""
echo "📊 Remaining containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 