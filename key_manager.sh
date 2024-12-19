#!/bin/bash
###############################################################################
# Key Management for servers
# 
# A utility script to manage SSH keys and connections to remote servers.
# Handles both IPv4 and IPv6 addresses, supports key generation, automatic
# key copying, and custom SSH ports.
#
# Usage:
#   ./key_manager.sh server_ip [-u] [-p password] [-P port] [-c] [-n keyname] [-q]
#
# Options:
#   server_ip        IP address of target server (IPv4/IPv6)
#   -u               Update existing SSH key
#   -p password      Root user password for key copying
#   -P port          Custom SSH port (default: 22)
#   -c               Force copy SSH key to server
#   -n keyname       Custom SSH key filename (default: id_rsa)
#   -q               Quiet mode for automation
#   -h               Show help message
#
# Requirements:
#   - ssh-keygen
#   - ssh-copy-id
#   - ssh
#   - sshpass (optional, for password-based auth)
#   - ssh-keyscan
#
# Author: Percio Andrade <percio@zendev.com.br>
# Version: 1.0
###############################################################################

# Help function
show_help() {
    echo "Usage: $0 server_ip [-u] [-p password] [-P port] [-c] [-n keyname] [-q]"
    echo "  server_ip        Specifies the IP address of the target server."
    echo "  -u               Updates the SSH key for the target server."
    echo "  -p password      Specifies the root user's password (used only if -c is set)."
    echo "  -P port          Specifies the SSH port of the target server (default: 22)."
    echo "  -c               Forces the copying of the SSH key to the server."
    echo "  -n keyname       Specifies a custom filename for the SSH key (default: id_rsa)."
    echo "  -q               Quiet mode: suppresses the output for automation tools."
    echo "  -h               Shows this help message and exits."
}

# Variables
SSH_USER="root"
SERVER_IP="$1"
UPDATE_KEY=false
ROOT_PASS=""
SSH_PORT=22
COPY_KEY=false
KEY_NAME="id_rsa"
QUIET_MODE=false

# Logging function with timestamp and quiet mode handling
log() {
    if [ "$QUIET_MODE" = false ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1"
    fi
}

# Validate IP address function for both IPv4 and IPv6
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0 # IPv4
    elif [[ $ip =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F]+$ ]]; then
        return 0 # IPv6
    else
        return 1 # Invalid IP address
    fi
}

# Check if is ipv6
is_ipv6() {
    local ip=$1
    if [[ $ip =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F]+$ ]]; then
        return 0 # IPv6
    else
        return 1 # Not IPv6
    fi
}

# Function to install missing commands
install_missing_command() {
    local cmd=$1
    log "Attempting to install $cmd..."
    if [[ -f /etc/debian_version ]]; then
        sudo apt-get update && sudo apt-get install -y $cmd
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum install -y $cmd
    else
        log "Unsupported system. Please install $cmd manually."
        exit 1
    fi
    if ! command -v $cmd &> /dev/null; then
        log "Failed to install $cmd."
        exit 1
    fi
}

# Check for required commands and install if they are missing
check_and_install_required_commands() {
    local missing_cmds=0
    for cmd in ssh-keygen ssh-copy-id ssh sshpass ssh-keyscan; do
        if ! command -v $cmd &> /dev/null; then
            log "Command not found: $cmd"
            install_missing_command $cmd
            missing_cmds=$((missing_cmds+1))
        fi
    done
    if [ $missing_cmds -ne 0 ]; then
        log "Please verify the installation of missing commands."
        exit 1
    fi
}

# Check if help was requested
if [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Initial IP address check
if ! [[ "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "Error: The first argument must be a valid IP address."
    exit 1
fi

# Process the remaining arguments
shift # Removes the IP address from the argument list

# Parse the command-line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u) UPDATE_KEY=true ;;
        -p) ROOT_PASS="$2"; shift ;;
        -P) SSH_PORT="$2"; shift ;;
        -c) COPY_KEY=true ;;
        -n) KEY_NAME="$2"; shift ;;
        -q) QUIET_MODE=true ;;
        -h) show_help; exit 0 ;;
        *) log "Invalid argument: $1"; exit 1 ;;
    esac
    shift
done

# Function to check and install sshpass if needed
check_install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        log "sshpass is not installed. Attempting to install..."
        if [[ -f /etc/debian_version ]]; then
            if [[ $(id -u) -eq 0 ]]; then
                apt-get update
                apt-get install -y sshpass
            else
                log "Insufficient permissions to install sshpass. Please install manually."
                exit 1
            fi
        elif [[ -f /etc/redhat-release ]]; then
            if [[ $(id -u) -eq 0 ]]; then
                yum install -y sshpass
            else
                log "Insufficient permissions to install sshpass. Please install manually."
                exit 1
            fi
        else
            log "Unsupported system. Please install sshpass manually."
            exit 1
        fi
    fi
}

# Function to check and create an SSH key if it does not exist
check_create_ssh_key() {
    local private_key="$HOME/.ssh/${KEY_NAME}"
    local public_key="${private_key}.pub"
    if [ ! -f "${private_key}" ] || [ ! -f "${public_key}" ] || [ "$UPDATE_KEY" = true ]; then
        log "SSH key not found or update requested. Creating a key with name ${KEY_NAME}..."
        # Create the private and public key
        yes | ssh-keygen -t rsa -b 4096 -C "${SSH_USER}@$(hostname)" -N "" -f "${private_key}"
        log "SSH key successfully created/updated with name ${KEY_NAME} for $SERVER_IP."
        COPY_KEY=true # New key must be copied to the server
    elif [ "$COPY_KEY" = true ]; then
        # If the key copy was explicitly requested with the -c option
        log "Copy key was requested. Preparing to copy the key ${KEY_NAME} to $SERVER_IP."
    fi
}

# Function to check if the SSH key has already been copied to the server
check_ssh_key_copied() {
    if grep -q "$SERVER_IP" "$HOME/.ssh/known_hosts" && [ "$COPY_KEY" = false ]; then
        return 0 # Key is already present, no need to copy
    else
        return 1 # Key is not present or needs updating, must copy
    fi
}

# Function to copy the SSH key to the target server with or without password
copy_ssh_key() {
    if [ "$COPY_KEY" = true ]; then
        if [ ! -z "$ROOT_PASS" ]; then
            check_install_sshpass
        fi
        if ! grep -q "$SERVER_IP" "$HOME/.ssh/known_hosts"; then
            ssh-keyscan -H -p "$SSH_PORT" "$SERVER_IP" >> "$HOME/.ssh/known_hosts"
        fi
        log "Copying the master key to the server $SERVER_IP on port $SSH_PORT..."
        if [ -z "$ROOT_PASS" ]; then
            ssh-copy-id -p "$SSH_PORT" "$SSH_USER@$SERVER_IP"
        else
            sshpass -p "$ROOT_PASS" ssh-copy-id -p "$SSH_PORT" "$SSH_USER@$SERVER_IP"
        fi
    fi
}

# Check for required commands before proceeding
check_and_install_required_commands

# Check and create the SSH key
check_create_ssh_key

# Check if the SSH key was copied correctly
if ! check_ssh_key_copied; then
    copy_ssh_key
fi

# Check if SSH user and server IP address have been specified
if [[ -z "$SSH_USER" ]]; then
    log "Error: SSH user not specified."
    exit 1
fi

# Ensure the SERVER_IP is set and valid
if ! validate_ip "$SERVER_IP"; then
    log "Error: Invalid IP address format."
    exit 1
fi

# If SSH port was not specified, use the default port
if [[ -z "$SSH_PORT" ]]; then
    SSH_PORT=22
fi

# Now attempts interactive SSH connection
if is_ipv6 "$SERVER_IP"; then
    ssh -p "$SSH_PORT" "$SSH_USER@[$SERVER_IP]" # Use colchetes para endereços IPv6
else
    ssh -p "$SSH_PORT" "$SSH_USER@$SERVER_IP" # Endereços IPv4 não precisam de colchetes
fi