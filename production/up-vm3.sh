#!/bin/bash

echo "Starting VM 3"

docker compose -f docker-compose-vm3.yml up --no-start

docker compose -f docker-compose-vm3.yml start roach-cert

sleep 10

docker compose -f docker-compose-vm3.yml start roach-2

echo "VM 3 (roach-2) started and joining cluster." 