#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-native"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: cmake is required."
    exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]] && ! [ -f /opt/homebrew/include/mosquitto.h ] && ! [ -f /usr/local/include/mosquitto.h ]; then
    echo "Error: libmosquitto headers not found."
    echo "Install dependencies with: brew install cmake mosquitto"
    exit 1
fi

echo "Building wmbus-gateway (native)..."
cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --parallel

echo "Build complete: $BUILD_DIR/wmbus-gateway"
