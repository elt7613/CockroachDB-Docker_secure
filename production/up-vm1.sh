#!/bin/bash

echo "Starting VM 1 (Bootstrap Node)"

docker compose -f docker-compose-vm1.yml up --no-start

docker compose -f docker-compose-vm1.yml start roach-cert

sleep 10

docker compose -f docker-compose-vm1.yml start roach-0

echo "VM 1 (roach-0) started. Wait for other VMs to join before running cluster init."
echo "After all VMs are up, run:"
echo "docker compose -f docker-compose-vm1.yml start roach-init" 