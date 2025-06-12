#!/bin/bash

echo "================================="
echo "CockroachDB Production Cluster"
echo "Starting 3-node secure cluster"
echo "================================="

echo ""
echo "📋 Cluster Information:"
echo "VM 1 (Bootstrap): 34.46.203.113:26257"
echo "VM 2: 34.133.173.136:26257"
echo "VM 3: 34.55.149.0:26257"
echo ""

echo "⚠️  IMPORTANT: Run this script on VM 1 ONLY"
echo "⚠️  Make sure VM 2 and VM 3 are ready to start"
echo ""

read -p "Press Enter to continue or Ctrl+C to cancel..."

echo ""
echo "🚀 Step 1: Starting VM 1 (Bootstrap Node)..."
./up-vm1.sh

echo ""
echo "⏳ Waiting 10 seconds for VM 1 to be ready..."
sleep 10

echo ""
echo "🔄 Step 2: Please start VM 2 now by running on VM 2:"
echo "   ./up-vm2.sh"
echo ""
read -p "Press Enter when VM 2 is started..."

echo ""
echo "🔄 Step 3: Please start VM 3 now by running on VM 3:"
echo "   ./up-vm3.sh"
echo ""
read -p "Press Enter when VM 3 is started..."

echo ""
echo "⏳ Waiting 15 seconds for all nodes to join..."
sleep 15

echo ""
echo "🔧 Step 4: Initializing cluster..."
docker compose -f docker-compose-vm1.yml start roach-init

echo ""
echo "⏳ Waiting for cluster initialization..."
sleep 10

echo ""
echo "✅ Cluster startup completed!"
echo ""
echo "🌐 Access Points:"
echo "Admin UI VM 1: https://34.46.203.113:9090"
echo "Admin UI VM 2: https://34.133.173.136:9090"
echo "Admin UI VM 3: https://34.55.149.0:9090"
echo ""
echo "📊 Check cluster status:"
echo "docker exec roach-0 cockroach node status --certs-dir=/certs --host=localhost:26257"
echo ""
echo "🔑 To apply enterprise license:"
echo "./apply_license.sh" 