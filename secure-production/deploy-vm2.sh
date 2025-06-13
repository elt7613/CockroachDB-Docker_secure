#!/bin/bash

# CockroachDB Secure Production Deployment Script - VM2 (Secondary Node)
# This script deploys a secondary CockroachDB node locally on VM2

set -e

# Load environment configuration
if [ -f "production.env" ]; then
    echo "Loading configuration from production.env..."
    source production.env
else
    echo "ERROR: production.env file is required but not found!"
    echo "Please run ./configure.sh first to create the configuration file."
    exit 1
fi

# Validate required environment variables
validate_environment() {
    local missing_vars=()
    
    # Check required variables
    [ -z "$VM1_IP" ] && missing_vars+=("VM1_IP")
    [ -z "$VM2_IP" ] && missing_vars+=("VM2_IP")  
    [ -z "$VM3_IP" ] && missing_vars+=("VM3_IP")
    [ -z "$CLUSTER_NAME" ] && missing_vars+=("CLUSTER_NAME")
    [ -z "$DATABASE_NAME" ] && missing_vars+=("DATABASE_NAME")
    [ -z "$COCKROACH_PORT" ] && missing_vars+=("COCKROACH_PORT")
    [ -z "$CONSOLE_PORT" ] && missing_vars+=("CONSOLE_PORT")
    [ -z "$COCKROACH_IMAGE" ] && missing_vars+=("COCKROACH_IMAGE")
    [ -z "$CERT_IMAGE" ] && missing_vars+=("CERT_IMAGE")
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "ERROR: Missing required environment variables:"
        printf '  %s\n' "${missing_vars[@]}"
        echo "Please check your production.env file and ensure all variables are set."
        exit 1
    fi
}

# Validate environment variables
validate_environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for VM2..."
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if vm2-docker-compose.yml exists
    if [ ! -f "vm2-docker-compose.yml" ]; then
        print_error "vm2-docker-compose.yml not found in current directory"
        exit 1
    fi
    
    # Check if production.env exists
    if [ ! -f "production.env" ]; then
        print_error "production.env file is required but not found!"
        print_error "Please run ./configure.sh first to create the configuration file."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker service."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to display configuration
display_config() {
    echo ""
    echo "=== VM2 Deployment Configuration ==="
    echo "VM1 IP: ${VM1_IP}"
echo "VM2 IP: ${VM2_IP}"
echo "VM3 IP: ${VM3_IP}"
echo "Cluster Name: ${CLUSTER_NAME}"
echo "Database: ${DATABASE_NAME}"
echo "CockroachDB Port: ${COCKROACH_PORT}"
echo "Console Port: ${CONSOLE_PORT}"
echo "Memory Limit: ${MEMORY_LIMIT}"
echo "CPU Limit: ${CPU_LIMIT}"
    echo ""
}

# Function to check VM1 connectivity
check_vm1_connectivity() {
    print_status "Checking connectivity to VM1 (primary node)..."
    
    local vm1_ip="${VM1_IP}"
    local cockroach_port="${COCKROACH_PORT}"
    
    # Test network connectivity to VM1
    if command_exists nc; then
        if nc -z "$vm1_ip" "$cockroach_port" 2>/dev/null; then
            print_success "VM1 is reachable on port $cockroach_port"
        else
            print_warning "Cannot reach VM1 on port $cockroach_port. Make sure VM1 is deployed first."
        fi
    else
        print_warning "netcat not available. Skipping connectivity check."
    fi
}

# Function to prepare deployment directory
prepare_deployment() {
    print_status "Preparing deployment directory..."
    
    # Create deployment directory if it doesn't exist
    mkdir -p ~/cockroachdb-secure
    
    # Copy necessary files
    cp vm2-docker-compose.yml ~/cockroachdb-secure/docker-compose.yml
    
    if [ -f "production.env" ]; then
        cp production.env ~/cockroachdb-secure/
        print_success "Copied production.env to deployment directory"
    fi
    
    cd ~/cockroachdb-secure
    print_success "Deployment directory prepared"
}

# Function to deploy services
deploy_services() {
    print_status "Deploying VM2 services..."
    
    # Pull latest images
    print_status "Pulling Docker images..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env pull
    else
        docker-compose pull
    fi
    
    # Start certificate service first
    print_status "Starting certificate generation service..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env up -d roach-cert
    else
        docker-compose up -d roach-cert
    fi
    
    # Wait for certificates to be generated
    print_status "Waiting for certificates to be generated..."
    sleep 20
    
    # Start secondary CockroachDB node
    print_status "Starting secondary CockroachDB node..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env up -d roach-1
    else
        docker-compose up -d roach-1
    fi
    
    # Start health monitor (optional)
    print_status "Starting health monitor..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env up -d health-monitor
    else
        docker-compose up -d health-monitor
    fi
    
    # Wait for node to be ready
    print_status "Waiting for CockroachDB node to be ready..."
    sleep 30
    
    print_success "VM2 services started successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying VM2 deployment..."
    
    echo ""
    echo "=== Container Status ==="
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env ps
    else
        docker-compose ps
    fi
    
    echo ""
    echo "=== Network Status ==="
    docker network ls | grep cockroach || echo "No CockroachDB networks found"
    
    echo ""
    echo "=== Volume Status ==="
    docker volume ls | grep vm2 || echo "No VM2 volumes found"
    
    print_success "VM2 deployment verification completed"
}

# Function to show connection information
show_connection_info() {
    echo ""
    echo "=== VM2 Connection Information ==="
    echo "DB Console: https://${VM2_IP}:${CONSOLE_PORT}"
    echo "CockroachDB Port: ${VM2_IP}:${COCKROACH_PORT}"
    echo ""
    echo "=== Management Commands ==="
    echo "Check node status:"
    echo "  docker exec -it roach-1-vm2 ./cockroach node status --certs-dir=/certs --host=localhost:${COCKROACH_PORT}"
    echo ""
    echo "Access SQL shell:"
    echo "  docker exec -it roach-1-vm2 ./cockroach sql --certs-dir=/certs --host=localhost:${COCKROACH_PORT}"
    echo ""
    echo "View logs:"
    echo "  docker-compose logs -f roach-1"
    echo ""
    echo "View health monitor logs:"
    echo "  docker-compose logs -f health-monitor"
    echo ""
    echo "Stop services:"
    echo "  docker-compose down"
}

# Function to show help
show_help() {
    echo "CockroachDB VM2 Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --verify-only   Only verify the current deployment"
    echo "  --stop          Stop all services"
    echo "  --restart       Restart all services"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Default behavior:"
    echo "  - Deploy certificate service and secondary CockroachDB node"
    echo "  - Start health monitoring service"
    echo ""
    echo "Note: Deploy VM1 (primary node) first before deploying VM2"
}

# Function to stop services
stop_services() {
    print_status "Stopping VM2 services..."
    cd ~/cockroachdb-secure
    
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env down
    else
        docker-compose down
    fi
    
    print_success "VM2 services stopped"
}

# Function to restart services
restart_services() {
    print_status "Restarting VM2 services..."
    cd ~/cockroachdb-secure
    
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env restart
    else
        docker-compose restart
    fi
    
    print_success "VM2 services restarted"
}

# Main function
main() {
    local mode="deploy"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verify-only)
                mode="verify"
                shift
                ;;
            --stop)
                mode="stop"
                shift
                ;;
            --restart)
                mode="restart"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "========================================"
    echo "CockroachDB VM2 (Secondary Node) Deployment"
    echo "========================================"
    echo ""
    
    case $mode in
        "deploy")
            check_prerequisites
            display_config
            check_vm1_connectivity
            
            # Ask for confirmation
            read -p "Deploy VM2 (Secondary Node)? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Deployment cancelled"
                exit 1
            fi
            
            prepare_deployment
            deploy_services
            verify_deployment
            show_connection_info
            
            echo ""
            print_warning "IMPORTANT: After deploying all nodes (VM1, VM2, VM3), initialize the cluster from VM1:"
            print_warning "  ssh to VM1 and run: ./deploy-vm1.sh --init-only"
            ;;
        "verify")
            cd ~/cockroachdb-secure
            verify_deployment
            show_connection_info
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
    esac
    
    print_success "VM2 deployment script completed!"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 