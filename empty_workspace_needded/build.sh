#!/bin/bash

# Build script for VS Code Server Docker container
# Supports setting git user name and email, with verbose logging

set -e

# Default values
VERBOSE=false
GIT_USER_NAME=""
GIT_USER_EMAIL=""
IMAGE_NAME="vscode-server-debian"
CONTAINER_NAME="vscode-server"
PORT=8080

# Function for verbose logging
log_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo "[VERBOSE] $1"
    fi
}

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -n, --name NAME         Git user name to configure inside the container
    -e, --email EMAIL       Git user email to configure inside the container
    -v, --verbose           Enable verbose logging
    -p, --port PORT         Port to expose (default: 8080)
    -i, --image-name NAME   Docker image name (default: vscode-server-debian)
    -c, --container-name NAME  Container name (default: vscode-server)
    -h, --help              Show this help message

Examples:
    $0 --name "John Doe" --email "john@example.com"
    $0 -n "Jane Smith" -e "jane@company.com" --verbose
    $0 --verbose --port 3000
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            GIT_USER_NAME="$2"
            shift 2
            ;;
        -e|--email)
            GIT_USER_EMAIL="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -i|--image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate git configuration (both name and email should be provided together)
if [[ -n "$GIT_USER_NAME" && -z "$GIT_USER_EMAIL" ]] || [[ -z "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    log_error "Both git user name and email must be provided together"
    exit 1
fi

# Display configuration
log_info "Starting build process..."
log_verbose "Build configuration:"
log_verbose "  Image name: $IMAGE_NAME"
log_verbose "  Container name: $CONTAINER_NAME"
log_verbose "  Port: $PORT"
log_verbose "  Verbose mode: $VERBOSE"
if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    log_verbose "  Git user name: $GIT_USER_NAME"
    log_verbose "  Git user email: $GIT_USER_EMAIL"
else
    log_verbose "  Git configuration: Not provided"
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running or not accessible"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    log_info "Stopping and removing existing container: $CONTAINER_NAME"
    log_verbose "Running: docker stop $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    log_verbose "Running: docker rm $CONTAINER_NAME"
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# Remove existing image if it exists
if docker images --format "table {{.Repository}}" | grep -q "^${IMAGE_NAME}$"; then
    log_info "Removing existing image: $IMAGE_NAME"
    log_verbose "Running: docker rmi $IMAGE_NAME"
    docker rmi "$IMAGE_NAME" >/dev/null 2>&1 || true
fi

# Build the Docker image
log_info "Building Docker image: $IMAGE_NAME"
log_verbose "Running: docker build -t $IMAGE_NAME ."

if [ "$VERBOSE" = "true" ]; then
    docker build -t "$IMAGE_NAME" .
else
    docker build -t "$IMAGE_NAME" . >/dev/null
fi

log_info "Docker image built successfully"

# Prepare environment variables for git configuration
ENV_VARS=""
if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    ENV_VARS="-e GIT_USER_NAME=\"$GIT_USER_NAME\" -e GIT_USER_EMAIL=\"$GIT_USER_EMAIL\""
    log_verbose "Git environment variables will be passed to container"
fi

# Add verbose flag if enabled
if [ "$VERBOSE" = "true" ]; then
    ENV_VARS="$ENV_VARS -e VERBOSE=true"
fi

# Run the container
log_info "Starting container: $CONTAINER_NAME"
log_verbose "Running: docker run -d --name $CONTAINER_NAME -p $PORT:8080 $ENV_VARS $IMAGE_NAME"

eval "docker run -d --name \"$CONTAINER_NAME\" -p $PORT:8080 $ENV_VARS \"$IMAGE_NAME\""

# Wait a moment for container to start
sleep 2

# Check if container is running
if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    log_info "Container started successfully"
    log_info "VS Code Server is available at: http://localhost:$PORT"
    
    if [ "$VERBOSE" = "true" ]; then
        log_verbose "Container logs:"
        docker logs "$CONTAINER_NAME"
    fi
else
    log_error "Container failed to start"
    log_info "Container logs:"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

log_info "Build and deployment complete!"

if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
    log_info "Git has been configured with:"
    log_info "  Name: $GIT_USER_NAME"
    log_info "  Email: $GIT_USER_EMAIL"
fi

log_info "Use 'docker logs $CONTAINER_NAME' to view container logs"
log_info "Use 'docker stop $CONTAINER_NAME' to stop the container"
