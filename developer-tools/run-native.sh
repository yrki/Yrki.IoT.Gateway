#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARY="$PROJECT_ROOT/build-native/wmbus-gateway"

if [ ! -x "$BINARY" ]; then
    echo "Binary not found: $BINARY"
    echo "Run build/build-native.sh first."
    exit 1
fi

exec "$BINARY" "$@"
