#!/bin/bash

# Entrypoint script for VS Code Server container
# This script configures git with provided user information and starts code-server

set -e

# Default values
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
VERBOSE="${VERBOSE:-false}"

# Function for verbose logging
log_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo "[VERBOSE] $1"
    fi
}

log_info() {
    echo "[INFO] $1"
}

# Configure git if name and email are provided
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    log_info "Configuring git with user information"
    log_verbose "Git user name: $GIT_USER_NAME"
    log_verbose "Git user email: $GIT_USER_EMAIL"
    
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    
    log_info "Git configuration complete"
else
    log_info "No git user information provided, skipping git configuration"
    if [ "$VERBOSE" = "true" ]; then
        log_verbose "GIT_USER_NAME: ${GIT_USER_NAME:-'not set'}"
        log_verbose "GIT_USER_EMAIL: ${GIT_USER_EMAIL:-'not set'}"
    fi
fi

# Display git configuration if verbose
if [ "$VERBOSE" = "true" ]; then
    log_verbose "Current git configuration:"
    git config --global --list | grep -E "^user\." || log_verbose "No user configuration found"
fi

log_info "Starting VS Code Server..."
log_verbose "Code-server will be available on port 8080"

# Start code-server
exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth none \
    --disable-telemetry \
    /home/vscode/workspace
