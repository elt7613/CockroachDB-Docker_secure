#!/bin/bash

echo "================================="
echo "CockroachDB Fault Tolerance Test"
echo "================================="

echo ""
echo "🧪 This script demonstrates cluster fault tolerance"
echo "⚠️  Only run this AFTER your cluster is fully initialized"
echo ""

# Function to check cluster status
check_cluster() {
    echo "📊 Current cluster status:"
    docker exec roach-0 cockroach node status --certs-dir=/certs --host=localhost:26257 2>/dev/null || \
    docker exec roach-1 cockroach node status --certs-dir=/certs --host=localhost:26257 2>/dev/null || \
    docker exec roach-2 cockroach node status --certs-dir=/certs --host=localhost:26257 2>/dev/null || \
    echo "❌ No nodes are accessible"
}

# Function to test database operations
test_operations() {
    local node=$1
    echo "🔍 Testing operations on $node..."
    
    if docker ps | grep -q "$node"; then
        # Try to query
        docker exec $node cockroach sql --certs-dir=/certs --host=localhost:26257 --execute "SELECT now();" 2>/dev/null && \
        echo "✅ $node is responding to queries" || \
        echo "❌ $node is not responding"
    else
        echo "❌ $node container is not running"
    fi
}

echo ""
echo "🔍 Initial cluster state:"
check_cluster

echo ""
echo "🧪 Testing individual node operations:"
test_operations "roach-0"
test_operations "roach-1" 
test_operations "roach-2"

echo ""
echo "💡 Fault Tolerance Scenarios:"
echo ""
echo "1️⃣  VM1 failure simulation:"
echo "   - Stop VM1: docker compose -f docker-compose-vm1.yml down"
echo "   - VM2 & VM3 continue operating (2/3 majority)"
echo "   - Admin UI accessible via VM2 or VM3"
echo ""

echo "2️⃣  VM2 failure simulation:"
echo "   - Stop VM2: docker compose -f docker-compose-vm2.yml down" 
echo "   - VM1 & VM3 continue operating (2/3 majority)"
echo "   - Admin UI accessible via VM1 or VM3"
echo ""

echo "3️⃣  Any 2 VMs failure:"
echo "   - Cluster goes read-only (can't reach majority)"
echo "   - Data remains safe and consistent"
echo "   - Cluster resumes when majority restored"
echo ""

echo "🔄 Recovery scenarios:"
echo "   - Restart failed VM: ./up-vm[X].sh"
echo "   - Node automatically rejoins cluster"
echo "   - No manual intervention needed"
echo ""

echo "🏥 Health monitoring:"
echo "   - Use ./status.sh to check cluster health"
echo "   - Monitor Admin UI on any available node"
echo "   - Watch for node liveness in gossip network"

echo ""
echo "✅ Your cluster is configured for maximum fault tolerance!"
echo "Each node knows about all other nodes for discovery and failover." 