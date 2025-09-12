#!/bin/bash
# Test: Container name matches tunnel_name in build_variables.yaml
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_VARS="$PROJECT_ROOT/build_variables.yaml"

# Extract tunnel_name from YAML (assumes key is at top-level)
tunnel_name=$(grep '^tunnel_name:' "$BUILD_VARS" | awk '{print $2}' | tr -d '"')
if [ -z "$tunnel_name" ]; then
  echo "[ERROR] tunnel_name not set in $BUILD_VARS"
  exit 1
fi

# Run build/start script (assumes build.sh creates the container)
bash "$PROJECT_ROOT/build.sh"

# Check if container exists with the tunnel_name
if docker ps -a --format '{{.Names}}' | grep -wq "$tunnel_name"; then
  echo "[SUCCESS] Container named '$tunnel_name' exists."
  exit 0
else
  echo "[ERROR] Container named '$tunnel_name' not found."
  exit 2
fi
