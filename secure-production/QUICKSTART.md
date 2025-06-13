# CockroachDB Secure Production - Quick Start Guide

## Pre-Deployment Checklist

### 1. Configure Environment Variables
Before deployment, you **MUST** configure your environment variables. You have two options:

**Option A: Interactive Configuration (Recommended)**
```bash
# Run the configuration script
chmod +x configure.sh
./configure.sh
```

**Option B: Manual Configuration**
```bash
# Copy the template and edit manually
./configure.sh
nano production.env
```

Update the VM IP addresses and other settings in `production.env`. The default IPs (`192.168.1.10`, `192.168.1.11`, `192.168.1.12`) must be replaced with your actual VM IPs.

### 2. VM Requirements
Ensure each VM has:
- **4GB+ RAM**
- **2+ CPU cores**
- **50GB+ storage**
- **Docker and Docker Compose installed**
- **SSH access configured**

### 3. Network Requirements
- **Port 26257**: Open between all VMs (CockroachDB)
- **Port 8080**: Open for DB Console access
- **SSH access**: Ensure you can SSH to all VMs

## Quick Deployment (Automated)

### 1. Configure Environment
```bash
# Make scripts executable
chmod +x configure.sh cleanup.sh deploy-vm1.sh deploy-vm2.sh deploy-vm3.sh

# Configure your environment (interactive)
./configure.sh

# Or for quick setup (VM IPs only)
./configure.sh --quick
```

### 2. Deploy to VMs

Since each node runs on a separate VM, you need to deploy to each VM individually:

```bash
# 1. Manually copy files to each VM (replace with your actual IPs and user)
scp vm1-docker-compose.yml production.env deploy-vm1.sh user@VM1_IP:~/
scp vm2-docker-compose.yml production.env deploy-vm2.sh user@VM2_IP:~/
scp vm3-docker-compose.yml production.env deploy-vm3.sh user@VM3_IP:~/

# 2. Make scripts executable on each VM
ssh user@VM1_IP "chmod +x deploy-vm1.sh"
ssh user@VM2_IP "chmod +x deploy-vm2.sh" 
ssh user@VM3_IP "chmod +x deploy-vm3.sh"

# 3. Deploy in order:
# First VM1 (primary):
ssh user@VM1_IP "./deploy-vm1.sh"

# Then VM2:
ssh user@VM2_IP "./deploy-vm2.sh"

# Then VM3:
ssh user@VM3_IP "./deploy-vm3.sh"

# Finally initialize cluster from VM1:
ssh user@VM1_IP "./deploy-vm1.sh --init-only"
```

## Manual Deployment (Step by Step)

### 1. Prepare VM1 (Primary Node)
```bash
# Copy files to VM1 (replace with your actual IP and user)
scp vm1-docker-compose.yml production.env deploy-vm1.sh user@VM1_IP:~/

# SSH to VM1 and run deployment script
ssh user@VM1_IP
chmod +x deploy-vm1.sh
./deploy-vm1.sh
```

### 2. Prepare VM2 (Secondary Node)
```bash
# Copy files to VM2 (replace with your actual IP and user)
scp vm2-docker-compose.yml production.env deploy-vm2.sh user@VM2_IP:~/

# SSH to VM2 and run deployment script
ssh user@VM2_IP
chmod +x deploy-vm2.sh
./deploy-vm2.sh
```

### 3. Prepare VM3 (Secondary Node)
```bash
# Copy files to VM3 (replace with your actual IP and user)
scp vm3-docker-compose.yml production.env deploy-vm3.sh user@VM3_IP:~/

# SSH to VM3 and run deployment script
ssh user@VM3_IP
chmod +x deploy-vm3.sh
./deploy-vm3.sh
```

### 4. Initialize Cluster
```bash
# Back on VM1, initialize the cluster
ssh user@VM1_IP
./deploy-vm1.sh --init-only
```

## Verification

### 1. Check Cluster Status
```bash
# From VM1
ssh user@192.168.1.10
cd ~/cockroachdb-secure

# Check cluster status
docker exec -it roach-0-vm1 ./cockroach node status --certs-dir=/certs --host=localhost:26257
```

### 2. Access DB Console
Open your browser to:
- **VM1**: `https://192.168.1.10:8080`
- **VM2**: `https://192.168.1.11:8080`
- **VM3**: `https://192.168.1.12:8080`

### 3. Test Database Connection
```bash
# Connect to SQL shell
docker exec -it roach-0-vm1 ./cockroach sql --certs-dir=/certs --host=localhost:26257

# Create a test database
CREATE DATABASE test;
SHOW DATABASES;
```

## Common Issues and Solutions

### Issue: Certificate Errors
**Solution**: Ensure all VM IPs are included in `NODE_ALTERNATIVE_NAMES` in all docker-compose files.

### Issue: Nodes Can't Join Cluster
**Solution**: 
- Check network connectivity between VMs on port 26257
- Verify firewall rules
- Ensure primary node is fully started before starting secondary nodes

### Issue: DB Console Not Accessible
**Solution**: 
- Check if port 8080 is open
- Verify the container is running: `docker ps`
- Check container logs: `docker-compose logs roach-0`

### Issue: SSH Connection Failed
**Solution**: 
- Verify SSH keys are configured
- Check if SSH service is running on target VMs
- Verify SSH connectivity to target VMs

## Cleanup

**Note**: Cleanup must be run locally on each VM where CockroachDB is deployed.

### Standard Cleanup (on each VM)
```bash
# SSH to each VM and run cleanup
ssh user@VM1_IP
cd ~/cockroachdb-secure
./cleanup.sh

ssh user@VM2_IP  
cd ~/cockroachdb-secure
./cleanup.sh

ssh user@VM3_IP
cd ~/cockroachdb-secure
./cleanup.sh
```

### Force Cleanup (removes all Docker resources on each VM)
```bash
# SSH to each VM and run force cleanup
ssh user@VM1_IP
cd ~/cockroachdb-secure
./cleanup.sh --force

ssh user@VM2_IP
cd ~/cockroachdb-secure
./cleanup.sh --force

ssh user@VM3_IP
cd ~/cockroachdb-secure
./cleanup.sh --force
```

## Next Steps

1. **Configure Load Balancer**: Set up a load balancer to distribute traffic across all nodes
2. **Set Up Monitoring**: Consider adding monitoring tools (Prometheus, Grafana)
3. **Backup Strategy**: Implement regular backup procedures
4. **Security Hardening**: Review and harden security settings
5. **Performance Tuning**: Adjust resource limits based on workload

## Connection Information

**Cluster Connection String**:
```
postgresql://admin:SecureP@ssw0rd123!@192.168.1.10:26257,192.168.1.11:26257,192.168.1.12:26257/production?sslmode=require
```

**Individual Node Connections**:
- **VM1**: `postgresql://admin:SecureP@ssw0rd123!@192.168.1.10:26257/production?sslmode=require`
- **VM2**: `postgresql://admin:SecureP@ssw0rd123!@192.168.1.11:26257/production?sslmode=require`
- **VM3**: `postgresql://admin:SecureP@ssw0rd123!@192.168.1.12:26257/production?sslmode=require`

## Support

For issues:
1. Check the logs: `docker-compose logs [service-name]`
2. Review the comprehensive README.md
3. Consult CockroachDB documentation: https://www.cockroachlabs.com/docs/ 