#!/bin/bash

echo "Starting VM 2"

docker compose -f docker-compose-vm2.yml up --no-start

docker compose -f docker-compose-vm2.yml start roach-cert

sleep 5

docker compose -f docker-compose-vm2.yml start roach-1

echo "VM 2 (roach-1) started and joining cluster successfully!" 