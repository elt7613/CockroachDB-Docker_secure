#!/bin/bash

# CockroachDB Secure Production Configuration Script
# This script helps you configure the environment variables for your deployment

set -e

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

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        if [ -z "$input" ]; then
            input="$default"
        fi
    else
        read -p "$prompt: " input
    fi
    
    eval "$var_name='$input'"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to load existing configuration
load_existing_config() {
    if [ -f "production.env" ]; then
        print_status "Loading existing configuration from production.env..."
        source production.env
        return 0
    else
        print_warning "No existing configuration found. Using defaults."
        return 1
    fi
}

# Function to configure VM settings
configure_vm_settings() {
    echo ""
    echo "=== VM Configuration ==="
    echo ""
    
    while true; do
        prompt_with_default "Enter VM1 IP address" "${VM1_IP}" VM1_IP
        if validate_ip "$VM1_IP"; then
            break
        else
            print_error "Invalid IP address format. Please try again."
        fi
    done
    
    while true; do
        prompt_with_default "Enter VM2 IP address" "${VM2_IP}" VM2_IP
        if validate_ip "$VM2_IP"; then
            break
        else
            print_error "Invalid IP address format. Please try again."
        fi
    done
    
    while true; do
        prompt_with_default "Enter VM3 IP address" "${VM3_IP}" VM3_IP
        if validate_ip "$VM3_IP"; then
            break
        else
            print_error "Invalid IP address format. Please try again."
        fi
    done
    

}

# Function to configure cluster settings
configure_cluster_settings() {
    echo ""
    echo "=== Cluster Configuration ==="
    echo ""
    
    prompt_with_default "Enter cluster name" "${CLUSTER_NAME}" CLUSTER_NAME
    prompt_with_default "Enter database name" "${DATABASE_NAME}" DATABASE_NAME
    prompt_with_default "Enter database admin username" "${DATABASE_USER}" DATABASE_USER
    
    while true; do
        prompt_with_default "Enter database admin password" "${DATABASE_PASSWORD}" DATABASE_PASSWORD
        if [ ${#DATABASE_PASSWORD} -ge 8 ]; then
            break
        else
            print_error "Password must be at least 8 characters long."
        fi
    done
}

# Function to configure resource settings
configure_resource_settings() {
    echo ""
    echo "=== Resource Configuration ==="
    echo ""
    
    prompt_with_default "Enter memory limit per container" "${MEMORY_LIMIT}" MEMORY_LIMIT
    prompt_with_default "Enter CPU limit per container" "${CPU_LIMIT}" CPU_LIMIT
    prompt_with_default "Enter memory reservation per container" "${MEMORY_RESERVATION}" MEMORY_RESERVATION
    prompt_with_default "Enter CPU reservation per container" "${CPU_RESERVATION}" CPU_RESERVATION
    prompt_with_default "Enter cache size" "${CACHE_SIZE}" CACHE_SIZE
    prompt_with_default "Enter max SQL memory" "${MAX_SQL_MEMORY}" MAX_SQL_MEMORY
}

# Function to configure network settings
configure_network_settings() {
    echo ""
    echo "=== Network Configuration ==="
    echo ""
    
    prompt_with_default "Enter Docker subnet" "${DOCKER_SUBNET}" DOCKER_SUBNET
    prompt_with_default "Enter CockroachDB port" "${COCKROACH_PORT}" COCKROACH_PORT
    prompt_with_default "Enter DB Console port" "${CONSOLE_PORT}" CONSOLE_PORT
}

# Function to configure advanced settings
configure_advanced_settings() {
    echo ""
    echo "=== Advanced Configuration ==="
    echo ""
    
    prompt_with_default "Enter additional node alternative names" "${NODE_ALTERNATIVE_NAMES_BASE}" NODE_ALTERNATIVE_NAMES_BASE
    prompt_with_default "Enter health check interval" "${HEALTH_CHECK_INTERVAL}" HEALTH_CHECK_INTERVAL
    prompt_with_default "Enter health check timeout" "${HEALTH_CHECK_TIMEOUT}" HEALTH_CHECK_TIMEOUT
    prompt_with_default "Enter health check retries" "${HEALTH_CHECK_RETRIES}" HEALTH_CHECK_RETRIES
    prompt_with_default "Enter health check start period" "${HEALTH_CHECK_START_PERIOD}" HEALTH_CHECK_START_PERIOD
    prompt_with_default "Enter log level" "${LOG_LEVEL}" LOG_LEVEL
    prompt_with_default "Enter log file verbosity" "${LOG_FILE_VERBOSITY}" LOG_FILE_VERBOSITY
}

# Function to configure Docker images
configure_docker_images() {
    echo ""
    echo "=== Docker Image Configuration ==="
    echo ""
    
    prompt_with_default "Enter CockroachDB image" "${COCKROACH_IMAGE}" COCKROACH_IMAGE
    prompt_with_default "Enter certificate image" "${CERT_IMAGE}" CERT_IMAGE
    prompt_with_default "Enter client image" "${CLIENT_IMAGE}" CLIENT_IMAGE
}

# Function to save configuration
save_configuration() {
    echo ""
    print_status "Saving configuration to production.env..."
    
    cat > production.env << EOF
# CockroachDB Secure Production Environment Configuration
# Generated on $(date)

# VM IP Addresses
VM1_IP=$VM1_IP
VM2_IP=$VM2_IP
VM3_IP=$VM3_IP

# VM SSH Configuration


# Cluster Configuration
CLUSTER_NAME=$CLUSTER_NAME
DATABASE_NAME=$DATABASE_NAME
DATABASE_USER=$DATABASE_USER
DATABASE_PASSWORD=$DATABASE_PASSWORD

# Resource Limits (per container)
MEMORY_LIMIT=$MEMORY_LIMIT
CPU_LIMIT=$CPU_LIMIT
MEMORY_RESERVATION=$MEMORY_RESERVATION
CPU_RESERVATION=$CPU_RESERVATION
CACHE_SIZE=$CACHE_SIZE
MAX_SQL_MEMORY=$MAX_SQL_MEMORY

# Network Configuration
DOCKER_SUBNET=$DOCKER_SUBNET
COCKROACH_PORT=$COCKROACH_PORT
CONSOLE_PORT=$CONSOLE_PORT

# Certificate Configuration
NODE_ALTERNATIVE_NAMES_BASE=$NODE_ALTERNATIVE_NAMES_BASE

# Health Check Configuration
HEALTH_CHECK_INTERVAL=$HEALTH_CHECK_INTERVAL
HEALTH_CHECK_TIMEOUT=$HEALTH_CHECK_TIMEOUT
HEALTH_CHECK_RETRIES=$HEALTH_CHECK_RETRIES
HEALTH_CHECK_START_PERIOD=$HEALTH_CHECK_START_PERIOD

# Logging Configuration
LOG_LEVEL=$LOG_LEVEL
LOG_FILE_VERBOSITY=$LOG_FILE_VERBOSITY

# Docker Image Versions
COCKROACH_IMAGE=$COCKROACH_IMAGE
CERT_IMAGE=$CERT_IMAGE
CLIENT_IMAGE=$CLIENT_IMAGE
EOF
    
    print_success "Configuration saved to production.env"
}

# Function to display configuration summary
display_summary() {
    echo ""
    echo "=== Configuration Summary ==="
    echo ""
    echo "VM Configuration:"
    echo "  VM1: $VM1_IP"
    echo "  VM2: $VM2_IP"
    echo "  VM3: $VM3_IP"

    echo ""
    echo "Cluster Configuration:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Database: $DATABASE_NAME"
    echo "  Admin User: $DATABASE_USER"
    echo ""
    echo "Network Configuration:"
    echo "  CockroachDB Port: $COCKROACH_PORT"
    echo "  Console Port: $CONSOLE_PORT"
    echo ""
    echo "Resource Configuration:"
    echo "  Memory Limit: $MEMORY_LIMIT"
    echo "  CPU Limit: $CPU_LIMIT"
    echo ""
    echo "Connection String:"
    echo "  postgresql://$DATABASE_USER:$DATABASE_PASSWORD@$VM1_IP:$COCKROACH_PORT,$VM2_IP:$COCKROACH_PORT,$VM3_IP:$COCKROACH_PORT/$DATABASE_NAME?sslmode=require"
}

# Function to show help
show_help() {
    echo "CockroachDB Secure Production Configuration Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -q, --quick     Quick configuration (VM IPs only)"
    echo "  -f, --full      Full configuration (all settings)"
    echo "  -r, --reset     Reset to default configuration"
    echo "  -s, --show      Show current configuration"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Interactive mode (default):"
    echo "  Prompts for all configuration options with current/default values"
}

# Main configuration function
main() {
    local mode="interactive"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -q|--quick)
                mode="quick"
                shift
                ;;
            -f|--full)
                mode="full"
                shift
                ;;
            -r|--reset)
                mode="reset"
                shift
                ;;
            -s|--show)
                mode="show"
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
    echo "CockroachDB Production Configuration"
    echo "========================================"
    echo ""
    
    # Load existing configuration
    load_existing_config
    
    case $mode in
        "quick")
            print_status "Quick configuration mode - VM IPs only"
            configure_vm_settings
            save_configuration
            ;;
        "full")
            print_status "Full configuration mode - all settings"
            configure_vm_settings
            configure_cluster_settings
            configure_resource_settings
            configure_network_settings
            configure_advanced_settings
            configure_docker_images
            save_configuration
            ;;
        "reset")
            print_warning "Resetting to default configuration..."
            rm -f production.env
            print_success "Configuration reset. Run ./configure.sh to create new configuration."
            exit 0
            ;;
        "show")
            if [ -f "production.env" ]; then
                print_status "Current configuration:"
                cat production.env
            else
                print_error "No configuration file found. Run ./configure.sh to create one."
                exit 1
            fi
            exit 0
            ;;
        "interactive")
            print_status "Interactive configuration mode"
            echo "Choose configuration level:"
            echo "1) Quick (VM IPs only)"
            echo "2) Standard (VM + Cluster settings)"
            echo "3) Full (All settings)"
            read -p "Enter choice [1-3]: " choice
            
            case $choice in
                1)
                    configure_vm_settings
                    ;;
                2)
                    configure_vm_settings
                    configure_cluster_settings
                    ;;
                3)
                    configure_vm_settings
                    configure_cluster_settings
                    configure_resource_settings
                    configure_network_settings
                    configure_advanced_settings
                    configure_docker_images
                    ;;
                *)
                    print_error "Invalid choice. Using quick configuration."
                    configure_vm_settings
                    ;;
            esac
            save_configuration
            ;;
    esac
    
    display_summary
    
    echo ""
    print_success "Configuration completed!"
    echo ""
    echo "Next steps:"
    echo "1. Review the configuration in production.env"
    echo "2. Run ./deploy.sh to deploy the cluster"
    echo "3. Use ./cleanup.sh to remove the deployment when needed"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 