# CockroachDB Production Cluster Setup

A secure, distributed CockroachDB cluster setup for production deployment across multiple VMs using Docker Compose.

## ⚙️ Configuration

Before deploying, you need to customize the configuration files with your actual VM IP addresses:

### **Step 1: Update IP Addresses**

Replace the following placeholders in **ALL configuration files**:
- `<VM1_IP>` → Your VM 1 IP address (e.g., `10.0.1.10`)
- `<VM2_IP>` → Your VM 2 IP address (e.g., `10.0.1.11`) 
- `<VM3_IP>` → Your VM 3 IP address (e.g., `10.0.1.12`)

### **Files to Update:**
1. `docker-compose-vm1.yml` - Update `hostname` and `advertise-addr` and `join` addresses
2. `docker-compose-vm2.yml` - Update `hostname` and `advertise-addr` and `join` addresses  
3. `docker-compose-vm3.yml` - Update `hostname` and `advertise-addr` and `join` addresses
4. Update `NODE_ALTERNATIVE_NAMES` in all files to include your actual IPs

### **Example Configuration:**
```yaml
# In docker-compose-vm1.yml
environment:
  - NODE_ALTERNATIVE_NAMES=10.0.1.10,10.0.1.11,10.0.1.12,localhost

roach-0:
  hostname: 10.0.1.10
  command: start --cluster-name=prod-secure --certs-dir=/certs --listen-addr=0.0.0.0:26257 --advertise-addr=10.0.1.10:26257 --join=10.0.1.10:26257,10.0.1.11:26257,10.0.1.12:26257
```

## 🏗️ Architecture

This setup creates a **3-node CockroachDB cluster** distributed across separate virtual machines:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  VM 1 (roach-0) │    │  VM 2 (roach-1) │    │  VM 3 (roach-2) │
│   <VM1_IP>      │◄───┤   <VM2_IP>      │◄───┤   <VM3_IP>      │
│ Port: 26257     │    │ Port: 26257     │    │ Port: 26257     │
│ Admin: 9090     │    │ Admin: 9090     │    │ Admin: 9090     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Features
- ✅ **High Availability**: Survives single node failures
- ✅ **Automatic Failover**: Built-in leader election
- ✅ **Data Replication**: 3x replication by default
- ✅ **TLS Security**: Auto-generated certificates
- ✅ **Load Distribution**: Connect to any node
- ✅ **Horizontal Scaling**: Easy to add more nodes

## 📁 Files Structure

```
production/
├── docker-compose-vm1.yml    # VM 1 configuration (Bootstrap + Init)
├── docker-compose-vm2.yml    # VM 2 configuration
├── docker-compose-vm3.yml    # VM 3 configuration
├── up-vm1.sh                 # VM 1 startup script
├── up-vm2.sh                 # VM 2 startup script
├── up-vm3.sh                 # VM 3 startup script
├── down.sh                   # Shutdown script (universal)
└── prune.sh                  # Cleanup script (universal)
```

## 🔧 Prerequisites

### VM Requirements (Each VM)
- **OS**: Ubuntu 20.04+ or similar
- **CPU**: 2+ cores
- **RAM**: 4GB+ 
- **Disk**: 20GB+ SSD
- **Network**: Static IP or reliable FQDN

### Software Dependencies
- **Docker & Docker Compose** - Required on all VMs
- **SSH Access** - For remote deployment and management

### Network Configuration
```bash
# Open required ports
sudo ufw allow 26257/tcp    # CockroachDB
sudo ufw allow 9090/tcp     # Admin UI
sudo ufw allow 22/tcp       # SSH
sudo ufw enable
```

## 🌐 Access Points

### Admin UI
- **VM 1**: https://\<VM1_IP\>:9090
- **VM 2**: https://\<VM2_IP\>:9090
- **VM 3**: https://\<VM3_IP\>:9090

### Database Connections
```bash
# Single node connection
postgresql://test:password@<VM1_IP>:26257/test?sslmode=require

# Multi-node connection (recommended)
postgresql://test:password@<VM1_IP>:26257,<VM2_IP>:26257,<VM3_IP>:26257/test?sslmode=require
```

## 🔍 Monitoring & Health Checks

### Check Node Status
```bash
# From any VM
docker exec roach-0 cockroach node status --certs-dir=/certs --host=localhost:26257
```

### Check Logs
```bash
# VM 1
docker logs roach-0

# VM 2  
docker logs roach-1

# VM 3
docker logs roach-2
```

### Health Endpoint
```bash
curl -k https://<VM1_IP>:9090/health?ready=1
```

## 🛡️ Security Features

### TLS Encryption
- **Auto-generated certificates** for all communications
- **Inter-node encryption** enabled by default
- **Client-server encryption** required

### Certificate Management
```bash
# View certificate details
docker exec roach-0 cockroach cert list --certs-dir=/certs

# Certificates include all node IPs:
# - <VM1_IP>
# - <VM2_IP>  
# - <VM3_IP>
# - localhost
```

### User Management
```bash
# Create additional users
docker exec -it roach-0 cockroach sql --certs-dir=/certs --host=localhost:26257
CREATE USER myuser WITH PASSWORD 'mypassword';
GRANT admin TO myuser;
```

## 🔧 Maintenance Operations

### Adding a New Node
1. **Create new VM** with Docker installed
2. **Create docker-compose-vm4.yml** with new IP
3. **Update join addresses** in all existing configs
4. **Restart cluster** with new configuration

### Backup Strategy
```bash
# Full cluster backup
docker exec roach-0 cockroach dump test --certs-dir=/certs --host=localhost:26257 > backup.sql

# Automated backup script
0 2 * * * /path/to/backup-script.sh
```

### Node Replacement
```bash
# Gracefully remove node
docker exec roach-0 cockroach node decommission 3 --certs-dir=/certs --host=localhost:26257

# Start replacement node
./up-vm-new.sh
```

## 🚨 Troubleshooting

### Common Issues

**Certificate Errors**
```bash
# Regenerate certificates
docker compose down
docker volume rm $(docker volume ls -q | grep certs)
docker compose up roach-cert
```

**Node Won't Join**
```bash
# Check network connectivity
telnet <VM1_IP> 26257

# Check firewall
sudo ufw status

# Verify join addresses match
docker logs roach-1 | grep "join"
```

**Split Brain Prevention**
- **Minimum 3 nodes** required for fault tolerance
- **Majority consensus** (2/3) needed for writes
- **Read-only mode** if only 1 node available

### Recovery Procedures

**Single Node Failure**
```bash
# Cluster continues with 2/3 nodes
# Restart failed node when ready
./up-vm1.sh  # Node automatically rejoins
```

**Multiple Node Failure**
```bash
# If 2+ nodes fail, cluster goes read-only
# Restart nodes one by one
# Manual intervention may be required
```

## 📈 Performance Tuning

### Resource Allocation
```yaml
# Add to docker-compose services
resources:
  limits:
    memory: 8G
    cpus: '4'
  reservations:
    memory: 4G
    cpus: '2'
```

### Storage Optimization
```bash
# Use SSDs for better performance
# Monitor disk space (75% threshold)
# Enable compression for large datasets
```

## 🔄 Scaling Operations

### Horizontal Scaling
1. **Add new VMs** to the cluster
2. **Update join addresses** in all configs
3. **Rolling restart** existing nodes
4. **Verify rebalancing** completion

### Vertical Scaling
1. **Stop node** gracefully
2. **Resize VM** resources
3. **Update resource limits** in docker-compose
4. **Restart node**
