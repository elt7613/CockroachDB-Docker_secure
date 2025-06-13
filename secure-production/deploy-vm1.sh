#!/bin/bash

# CockroachDB Secure Production Deployment Script - VM1 (Primary Node)
# This script deploys the primary CockroachDB node locally on VM1

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
    print_status "Checking prerequisites for VM1..."
    
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
    
    # Check if vm1-docker-compose.yml exists
    if [ ! -f "vm1-docker-compose.yml" ]; then
        print_error "vm1-docker-compose.yml not found in current directory"
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
    echo "=== VM1 Deployment Configuration ==="
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

# Function to prepare deployment directory
prepare_deployment() {
    print_status "Preparing deployment directory..."
    
    # Create deployment directory if it doesn't exist
    mkdir -p ~/cockroachdb-secure
    
    # Copy necessary files
    cp vm1-docker-compose.yml ~/cockroachdb-secure/docker-compose.yml
    
    if [ -f "production.env" ]; then
        cp production.env ~/cockroachdb-secure/
        print_success "Copied production.env to deployment directory"
    fi
    
    cd ~/cockroachdb-secure
    print_success "Deployment directory prepared"
}

# Function to deploy services
deploy_services() {
    print_status "Deploying VM1 services..."
    
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
    
    # Start primary CockroachDB node
    print_status "Starting primary CockroachDB node..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env up -d roach-0
    else
        docker-compose up -d roach-0
    fi
    
    # Wait for node to be ready
    print_status "Waiting for CockroachDB node to be ready..."
    sleep 30
    
    print_success "VM1 services started successfully"
}

# Function to initialize cluster (only after all nodes are running)
initialize_cluster() {
    echo ""
    print_warning "IMPORTANT: Cluster initialization should only be done AFTER all 3 nodes are running!"
    print_warning "Make sure VM2 and VM3 nodes are deployed and healthy before proceeding."
    echo ""
    
    read -p "Are VM2 and VM3 nodes running and healthy? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Skipping cluster initialization. Run this script with --init-only flag later."
        return 0
    fi
    
    print_status "Initializing CockroachDB cluster..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env up -d roach-init
    else
        docker-compose up -d roach-init
    fi
    
    # Wait for initialization to complete
    sleep 20
    
    # Check initialization logs
    print_status "Checking cluster initialization..."
    docker-compose logs roach-init
    
    print_success "Cluster initialization completed"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying VM1 deployment..."
    
    # Check container status
    echo ""
    echo "=== Container Status ==="
    docker-compose ps
    
    # Check node status
    echo ""
    echo "=== CockroachDB Node Status ==="
    if docker exec roach-0-vm1 ./cockroach node status --certs-dir=/certs --host=localhost:${COCKROACH_PORT} 2>/dev/null; then
        print_success "Node status check passed"
    else
        print_warning "Node status check failed (this is normal if cluster is not initialized yet)"
    fi
    
    # Check logs
    echo ""
    echo "=== Recent Logs ==="
    docker-compose logs --tail=10 roach-0
}

# Function to show connection information
show_connection_info() {
    echo ""
    echo "=== VM1 Connection Information ==="
    echo "DB Console: https://${VM1_IP}:${CONSOLE_PORT}"
    echo "CockroachDB Port: ${VM1_IP}:${COCKROACH_PORT}"
    echo ""
    echo "=== Management Commands ==="
    echo "Check node status:"
    echo "  docker exec -it roach-0-vm1 ./cockroach node status --certs-dir=/certs --host=localhost:${COCKROACH_PORT}"
    echo ""
    echo "Access SQL shell:"
    echo "  docker exec -it roach-0-vm1 ./cockroach sql --certs-dir=/certs --host=localhost:${COCKROACH_PORT}"
    echo ""
    echo "View logs:"
    echo "  docker-compose logs -f roach-0"
    echo ""
    echo "Stop services:"
    echo "  docker-compose down"
}

# Function to show help
show_help() {
    echo "CockroachDB VM1 Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --init-only     Only initialize the cluster (run after all nodes are deployed)"
    echo "  --verify-only   Only verify the current deployment"
    echo "  --stop          Stop all services"
    echo "  --restart       Restart all services"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Default behavior:"
    echo "  - Deploy certificate service and primary CockroachDB node"
    echo "  - Optionally initialize cluster if other nodes are ready"
}

# Function to stop services
stop_services() {
    print_status "Stopping VM1 services..."
    cd ~/cockroachdb-secure
    
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env down
    else
        docker-compose down
    fi
    
    print_success "VM1 services stopped"
}

# Function to restart services
restart_services() {
    print_status "Restarting VM1 services..."
    cd ~/cockroachdb-secure
    
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env restart
    else
        docker-compose restart
    fi
    
    print_success "VM1 services restarted"
}

# Main function
main() {
    local mode="deploy"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --init-only)
                mode="init"
                shift
                ;;
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
    echo "CockroachDB VM1 (Primary Node) Deployment"
    echo "========================================"
    echo ""
    
    case $mode in
        "deploy")
            check_prerequisites
            display_config
            
            # Ask for confirmation
            read -p "Deploy VM1 (Primary Node)? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Deployment cancelled"
                exit 1
            fi
            
            prepare_deployment
            deploy_services
            initialize_cluster
            verify_deployment
            show_connection_info
            ;;
        "init")
            cd ~/cockroachdb-secure
            initialize_cluster
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
    
    print_success "VM1 deployment script completed!"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 