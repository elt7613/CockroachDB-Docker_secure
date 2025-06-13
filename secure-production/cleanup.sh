#!/bin/bash

# CockroachDB Secure Production Cleanup Script
# This script helps clean up the CockroachDB cluster deployment locally
# Run this script on each VM where CockroachDB is deployed

set -e

# Load environment configuration
if [ -f "production.env" ]; then
    echo "Loading configuration from production.env..."
    source production.env
else
    echo "ERROR: production.env file is required but not found!"
    echo "Please ensure production.env is present in the current directory."
    exit 1
fi

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

# Function to cleanup local deployment
cleanup_local() {
    print_status "Cleaning up local CockroachDB deployment..."
    
    # Check if we're in the deployment directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in current directory"
        print_error "Please run this script from the cockroachdb-secure directory"
        exit 1
    fi
    
    # Stop and remove containers
    print_status "Stopping and removing containers..."
    if [ -f "production.env" ]; then
        docker-compose --env-file production.env down -v --remove-orphans || true
    else
        docker-compose down -v --remove-orphans || true
    fi
    
    # Remove Docker images (optional)
    print_status "Cleaning up Docker images..."
    docker image prune -f || true
    
    print_success "Local cleanup completed"
}

# Function to force cleanup (removes everything)
force_cleanup() {
    print_warning "Performing force cleanup (removes all Docker resources)..."
    
    # Stop all containers
    print_status "Stopping all containers..."
    docker stop $(docker ps -q) 2>/dev/null || true
    
    # Remove all containers
    print_status "Removing all containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Remove all volumes
    print_status "Removing all volumes..."
    docker volume prune -f || true
    
    # Remove all networks
    print_status "Removing all networks..."
    docker network prune -f || true
    
    # Remove all images
    print_status "Removing all images..."
    docker image prune -af || true
    
    print_success "Force cleanup completed"
}

# Function to show help
show_help() {
    echo "CockroachDB Secure Production Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script must be run locally on each VM where CockroachDB is deployed."
    echo "Run from the cockroachdb-secure directory containing docker-compose.yml"
    echo ""
    echo "Options:"
    echo "  -f, --force     Force cleanup (removes all Docker resources)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Default behavior:"
    echo "  - Stops and removes CockroachDB containers"
    echo "  - Removes Docker volumes"
    echo "  - Preserves Docker images for faster redeployment"
    echo ""
    echo "Force cleanup behavior:"
    echo "  - Stops and removes ALL containers on this VM"
    echo "  - Removes ALL Docker volumes, networks, and images"
    echo "  - Use with caution on shared systems"
}

# Main cleanup function
main() {
    local force_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_mode=true
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
    echo "CockroachDB Secure Production Cleanup"
    echo "========================================"
    echo ""
    
    if [ "$force_mode" = true ]; then
        print_warning "FORCE MODE ENABLED - This will remove ALL Docker resources on this VM!"
        echo ""
        read -p "Are you sure you want to proceed with force cleanup? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Force cleanup cancelled"
            exit 1
        fi
        
        force_cleanup
    else
        print_status "Standard cleanup mode - cleaning up CockroachDB deployment"
        echo ""
        read -p "Do you want to proceed with cleanup? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Cleanup cancelled"
            exit 1
        fi
        
        # Perform standard cleanup
        cleanup_local
    fi
    
    print_success "Cleanup completed successfully!"
    echo ""
    echo "=== Cleanup Summary ==="
    if [ "$force_mode" = true ]; then
        echo "- Removed ALL Docker containers, volumes, networks, and images on this VM"
    else
        echo "- Removed CockroachDB containers and volumes on this VM"
        echo "- Preserved Docker images for faster redeployment"
    fi
    echo "- Local cleanup completed"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 