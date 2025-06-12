#!/bin/bash

echo "================================="
echo "CockroachDB Cluster Debug"
echo "================================="

echo ""
echo "🔍 Step 1: Container Status"
echo "----------------------------"
docker compose -f docker-compose-vm1.yml ps
echo ""

echo "🔍 Step 2: Certificate Generation Logs"
echo "---------------------------------------"
echo "Checking roach-cert logs..."
docker logs roach-cert --tail 20
echo ""

echo "🔍 Step 3: Node Startup Logs"
echo "-----------------------------"
echo "Checking roach-0 logs..."
docker logs roach-0 --tail 20
echo ""

echo "🔍 Step 4: Initialization Logs"
echo "-------------------------------"
echo "Checking roach-init logs..."
docker logs roach-init --tail 20
echo ""

echo "🔍 Step 5: Certificate Files"
echo "-----------------------------"
echo "Checking if certificates were generated..."
docker exec roach-0 ls -la /certs/ 2>/dev/null || echo "❌ Cannot access certificate directory"
echo ""

echo "🔍 Step 6: Node Status Check"
echo "-----------------------------"
echo "Trying different connection methods..."

# Try connecting without TLS first to see if node is responding
echo "Attempting insecure connection test..."
docker exec roach-0 /cockroach/cockroach sql --insecure --host=localhost:26257 --execute "SELECT 1;" 2>/dev/null && echo "✅ Node responds to insecure connections" || echo "❌ Node not responding to insecure connections"

# Try with certificates
echo "Attempting secure connection..."
docker exec roach-0 /cockroach/cockroach sql --certs-dir=/certs --host=localhost:26257 --execute "SELECT 1;" 2>/dev/null && echo "✅ Node responds to secure connections" || echo "❌ Node not responding to secure connections"

echo ""
echo "🔍 Step 7: Network Connectivity"
echo "--------------------------------"
echo "Checking internal network connectivity..."
docker exec roach-0 ping -c 2 roach-cert 2>/dev/null && echo "✅ Can reach roach-cert" || echo "❌ Cannot reach roach-cert"

echo ""
echo "🔍 Step 8: Process Status"
echo "-------------------------"
echo "Checking cockroach process in roach-0..."
docker exec roach-0 ps aux | grep cockroach

echo ""
echo "💡 Troubleshooting Recommendations:"
echo "======================================"
echo ""

# Check if roach-init is still running
if docker ps | grep -q roach-init; then
    echo "⚠️  roach-init is still running - cluster initialization may be in progress"
    echo "   Wait a few more minutes or check logs above"
else
    echo "✅ roach-init has completed (container stopped)"
fi

echo ""
echo "🔧 Common Solutions:"
echo "1. If certificates failed: Restart roach-cert"
echo "   docker compose -f docker-compose-vm1.yml restart roach-cert"
echo ""
echo "2. If node failed to start: Restart roach-0"
echo "   docker compose -f docker-compose-vm1.yml restart roach-0"
echo ""
echo "3. If initialization failed: Restart roach-init"
echo "   docker compose -f docker-compose-vm1.yml restart roach-init"
echo ""
echo "4. Nuclear option - full restart:"
echo "   ./down-vm1.sh && sleep 5 && ./up-vm1.sh" 