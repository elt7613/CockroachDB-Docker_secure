#!/bin/bash

echo "================================="
echo "CockroachDB Cluster Status Check"
echo "================================="

echo ""
echo "🔍 Checking Docker containers..."
echo ""

echo "VM 1 containers:"
docker compose -f docker-compose-vm1.yml ps

echo ""
echo "📊 Cluster Node Status:"
echo ""

# Check if roach-0 is running before trying to query it
if docker ps | grep -q "roach-0"; then
    echo "Querying cluster status from roach-0..."
    docker exec roach-0 cockroach node status --certs-dir=/certs --host=localhost:26257
    
    echo ""
    echo "🏥 Cluster Health:"
    docker exec roach-0 cockroach sql --certs-dir=/certs --host=localhost:26257 --execute "SELECT node_id, address, is_available, is_live FROM crdb_internal.gossip_liveness ORDER BY node_id;"
    
    echo ""
    echo "💾 Database Information:"
    docker exec roach-0 cockroach sql --certs-dir=/certs --host=localhost:26257 --execute "SHOW DATABASES;"
    
    echo ""
    echo "👥 Users:"
    docker exec roach-0 cockroach sql --certs-dir=/certs --host=localhost:26257 --execute "SHOW USERS;"
    
else
    echo "❌ roach-0 container is not running!"
    echo "Run ./up-vm1.sh to start VM 1"
fi

echo ""
echo "🌐 Admin UI Access:"
echo "VM 1: https://34.55.149.0:9090"
echo "VM 2: https://34.133.173.136:9090"
echo "VM 3: https://34.46.203.113:9090"

echo ""
echo "🔗 Connection String:"
echo "postgresql://test:password@34.55.149.0:26257,34.133.173.136:26257,34.46.203.113:26257/test?sslmode=require" 