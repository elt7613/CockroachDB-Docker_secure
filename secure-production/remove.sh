# Stop all running containers
sudo docker stop $(sudo docker ps -q) 2>/dev/null || true

# Remove all containers (running and stopped)
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

# Remove all volumes
sudo docker volume prune -f

# Remove all networks (except default ones)
sudo docker network prune -f

# Remove all unused images (optional)
sudo docker image prune -af