#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/deploy/config-rpi.env"

REMOTE_BUILD_DIR="/tmp/wmbus-gateway-build"

# Build SSH command with password support
if [ -n "${PI_PASS:-}" ]; then
    if ! command -v sshpass &> /dev/null; then
        echo "Error: sshpass is required for password auth. Install with: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
    SSH="sshpass -p $PI_PASS ssh"
    SCP="sshpass -p $PI_PASS scp"
    RSYNC_RSH="sshpass -p $PI_PASS ssh"
else
    SSH="ssh"
    SCP="scp"
    RSYNC_RSH="ssh"
fi

echo "Installing build dependencies on ${PI_HOST}..."
$SSH "$PI_USER@$PI_HOST" "sudo apt-get update -qq && sudo apt-get install -y -qq cmake g++ libmosquitto-dev"

echo "Copying source to ${PI_HOST}:${REMOTE_BUILD_DIR}..."
$SSH "$PI_USER@$PI_HOST" "rm -rf $REMOTE_BUILD_DIR && mkdir -p $REMOTE_BUILD_DIR"
rsync -az --exclude='build*' -e "$RSYNC_RSH" "$PROJECT_ROOT/" "$PI_USER@$PI_HOST:$REMOTE_BUILD_DIR/"

echo "Building wmbus-gateway on ${PI_HOST}..."
$SSH "$PI_USER@$PI_HOST" "cd $REMOTE_BUILD_DIR && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --parallel"

echo "Build complete: ${PI_HOST}:${REMOTE_BUILD_DIR}/build/wmbus-gateway"
