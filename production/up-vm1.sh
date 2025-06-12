#!/bin/bash

echo "Starting VM 1 (Bootstrap Node)"

docker compose -f docker-compose-vm1.yml up --no-start

docker compose -f docker-compose-vm1.yml start roach-cert

sleep 5

docker compose -f docker-compose-vm1.yml start roach-0

echo "VM 1 (roach-0) started successfully!"
echo "Now you can start other VMs (VM2 and VM3)"
echo "After all VMs are up, run cluster initialization:"
echo "docker compose -f docker-compose-vm1.yml start roach-init" 