# CockroachDB Secure Production Deployment

This directory contains the configuration files for deploying a secure CockroachDB cluster across 3 different VMs using Docker.

## Architecture Overview

- **3 VMs** running CockroachDB nodes in a secure cluster
- **TLS 1.3 encryption** for all inter-node and client communications
- **Production-ready** configuration with proper resource limits
- **Certificate-based security** with automatic certificate generation
- **High availability** with fault tolerance

## VM Requirements

### Minimum System Requirements (per VM)
- **CPU**: 2+ cores
- **Memory**: 4GB+ RAM
- **Storage**: 50GB+ available disk space
- **Network**: Static IP addresses with inter-VM connectivity
- **OS**: Linux with Docker and Docker Compose installed

### Network Requirements
- **Port 26257**: CockroachDB cluster communication (must be accessible between VMs)
- **Port 8080**: DB Console access (optional, can be restricted)
- **Port 443/80**: HTTPS/HTTP for certificate management (if needed)

## Environment Configuration

This deployment uses environment variables for easy configuration management. All settings are centralized in the `production.env` file.

### Configuration Methods

**Method 1: Interactive Configuration (Recommended)**
```bash
chmod +x configure.sh
./configure.sh
```

**Method 2: Quick Configuration (VM IPs only)**
```bash
./configure.sh --quick
```

**Method 3: Manual Configuration**
```bash
./configure.sh
nano production.env
```

### Expected VM Layout
- **VM1 (Node 0)**: Primary node - `192.168.1.10` (configurable via `VM1_IP`)
- **VM2 (Node 1)**: Secondary node - `192.168.1.11` (configurable via `VM2_IP`)
- **VM3 (Node 2)**: Secondary node - `192.168.1.12` (configurable via `VM3_IP`)

**⚠️ IMPORTANT**: Configure your actual VM IPs using the configuration script or by editing `production.env`.

### Configurable Parameters

The following parameters can be configured via environment variables:

**VM Configuration:**
- `VM1_IP`, `VM2_IP`, `VM3_IP` - VM IP addresses


**Cluster Configuration:**
- `CLUSTER_NAME` - CockroachDB cluster name
- `DATABASE_NAME` - Default database name
- `DATABASE_USER`, `DATABASE_PASSWORD` - Admin credentials

**Resource Configuration:**
- `MEMORY_LIMIT`, `CPU_LIMIT` - Container resource limits
- `CACHE_SIZE`, `MAX_SQL_MEMORY` - CockroachDB memory settings

**Network Configuration:**
- `COCKROACH_PORT` - CockroachDB communication port
- `CONSOLE_PORT` - DB Console web interface port
- `DOCKER_SUBNET` - Docker network subnet

**Advanced Configuration:**
- Health check settings, logging levels, Docker image versions

## Certificate Management

This deployment uses `timveil/cockroachdb-dynamic-certs` for automatic certificate generation:
- **CA Certificate**: Shared across all nodes
- **Node Certificates**: Include all VM IPs in Subject Alternative Names
- **Client Certificates**: For secure client connections

## Deployment Steps

### 1. Prepare Each VM

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
sudo apt install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again for group changes to take effect

# Verify Docker installation
docker --version
docker-compose --version
```

### 2. Deploy Cluster

#### On VM1 (Primary Node):
```bash
# Copy files to VM1 (replace with your actual IP and user)
scp vm1-docker-compose.yml production.env deploy-vm1.sh user@VM1_IP:~/

# SSH to VM1 and run deployment script
ssh user@VM1_IP
chmod +x deploy-vm1.sh
./deploy-vm1.sh
```

#### On VM2 (Secondary Node):
```bash
# Copy files to VM2 (replace with your actual IP and user)
scp vm2-docker-compose.yml production.env deploy-vm2.sh user@VM2_IP:~/

# SSH to VM2 and run deployment script
ssh user@VM2_IP
chmod +x deploy-vm2.sh
./deploy-vm2.sh
```

#### On VM3 (Secondary Node):
```bash
# Copy files to VM3 (replace with your actual IP and user)
scp vm3-docker-compose.yml production.env deploy-vm3.sh user@VM3_IP:~/

# SSH to VM3 and run deployment script
ssh user@VM3_IP
chmod +x deploy-vm3.sh
./deploy-vm3.sh
```

### 3. Initialize Cluster

After all nodes are running, initialize the cluster from VM1:

```bash
# On VM1, initialize the cluster
ssh user@VM1_IP
./deploy-vm1.sh --init-only
```

### 4. Verify Cluster Status

```bash
# From any VM, check cluster status
docker exec -it roach-0 ./cockroach node status --certs-dir=/certs --host=roach-0:26257

# Access DB Console (from VM1)
# Open browser to: https://192.168.1.10:8080
```

## Management Commands

### Check Cluster Health
```bash
# Check node status
docker exec -it roach-0 ./cockroach node status --certs-dir=/certs --host=roach-0:26257

# Check cluster status
docker exec -it roach-0 ./cockroach cluster status --certs-dir=/certs --host=roach-0:26257
```

### Access SQL Shell
```bash
# Connect to SQL shell
docker exec -it roach-0 ./cockroach sql --certs-dir=/certs --host=roach-0:26257
```

### Backup and Restore
```bash
# Create backup
docker exec -it roach-0 ./cockroach dump --certs-dir=/certs --host=roach-0:26257 defaultdb > backup.sql

# Load backup
docker exec -i roach-0 ./cockroach sql --certs-dir=/certs --host=roach-0:26257 < backup.sql
```

## Troubleshooting

### Common Issues

1. **Certificate Issues**
   - Ensure all nodes can resolve each other's hostnames
   - Check that certificates include all IP addresses in SAN
   - Verify certificate permissions and validity

2. **Network Connectivity**
   - Test connectivity between VMs on port 26257
   - Check firewall rules
   - Verify DNS resolution

3. **Node Join Issues**
   - Ensure primary node (roach-0) is fully started before starting other nodes
   - Check join address configuration
   - Verify network connectivity

### Log Analysis
```bash
# View container logs
docker-compose logs roach-0
docker-compose logs roach-cert

# Follow logs in real-time
docker-compose logs -f roach-0
```

## Security Considerations

- **TLS Encryption**: All communications are encrypted with TLS 1.3
- **Certificate Rotation**: Certificates should be rotated regularly
- **Network Security**: Restrict port access using firewalls
- **Regular Updates**: Keep CockroachDB and Docker images updated
- **Backup Security**: Encrypt backups and store securely

## Monitoring and Maintenance

### Health Checks
```bash
# Check if nodes are responsive
curl -k https://192.168.1.10:8080/health?ready=1
curl -k https://192.168.1.11:8080/health?ready=1
curl -k https://192.168.1.12:8080/health?ready=1
```

### Resource Monitoring
```bash
# Check Docker resource usage
docker stats

# Check disk usage
df -h
```

## Scaling

To add more nodes to the cluster:
1. Deploy a new VM with the same configuration
2. Update the certificate configuration to include the new node's IP
3. Start the new node with the `--join` parameter pointing to existing nodes
4. The new node will automatically join the cluster

## Support

For issues and questions:
- Check CockroachDB documentation: https://www.cockroachlabs.com/docs/
- Review Docker logs for error messages
- Verify network connectivity between VMs
- Ensure proper certificate configuration 