#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Banner
echo -e "${CYAN}"
cat << 'BANNER'
     __ __     _   _
    |  |  |___| |_|_|
    |_   _|  _| '_| |     Y R K I  ·  I o T · G a t e w a y
      |_| |_| |_,_|_|

BANNER
echo -e "${NC}"
echo -e "  ${DIM}WMBus Gateway Deployer — Raspberry Pi (C++)${NC}"
echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/config-rpi.env"

REMOTE_BUILD_DIR="/tmp/wmbus-gateway-build"
REMOTE_DIR="/opt/wmbus-gateway"
SERVICE_NAME="wmbus-gateway"

# Prompt for configuration (defaults from config-rpi.env)
echo -e "  ${BOLD}${MAGENTA}Raspberry Pi${NC}"
echo -e "  ${DIM}────────────${NC}"
read -rp $'  \033[0;36mHostname\033[0m [\033[2m'"${PI_HOST}"$'\033[0m]: ' input
PI_HOST="${input:-$PI_HOST}"

read -rp $'  \033[0;36mUsername\033[0m [\033[2m'"${PI_USER}"$'\033[0m]: ' input
PI_USER="${input:-$PI_USER}"

read -rsp $'  \033[0;36mPassword\033[0m [\033[2mempty = SSH key\033[0m]: ' PI_PASS
echo

echo ""
echo -e "  ${BOLD}${MAGENTA}Gateway${NC}"
echo -e "  ${DIM}───────${NC}"
read -rp $'  \033[0;36mGateway ID\033[0m [\033[2mhostname\033[0m]: ' input
GATEWAY_ID="${input:-${GATEWAY_ID:-}}"

read -rp $'  \033[0;36mSerial port\033[0m [\033[2m'"${SERIAL_PORT}"$'\033[0m]: ' input
SERIAL_PORT="${input:-$SERIAL_PORT}"

echo ""
echo -e "  ${BOLD}${MAGENTA}MQTT${NC}"
echo -e "  ${DIM}────${NC}"
read -rp $'  \033[0;36mHost\033[0m [\033[2m'"${MQTT_HOST}"$'\033[0m]: ' input
MQTT_HOST="${input:-$MQTT_HOST}"

read -rp $'  \033[0;36mPort\033[0m [\033[2m'"${MQTT_PORT}"$'\033[0m]: ' input
MQTT_PORT="${input:-$MQTT_PORT}"

read -rp $'  \033[0;36mTopic\033[0m [\033[2m'"${MQTT_TOPIC}"$'\033[0m]: ' input
MQTT_TOPIC="${input:-$MQTT_TOPIC}"

# Build SSH/SCP command with password support via sshpass if needed
if [ -n "$PI_PASS" ]; then
    if ! command -v sshpass &> /dev/null; then
        echo -e "\n  ${RED}Error: sshpass is required for password auth. Install with: brew install hudochenkov/sshpass/sshpass${NC}"
        exit 1
    fi
    SSH="sshpass -p $PI_PASS ssh"
    RSYNC_RSH="sshpass -p $PI_PASS ssh"
    export PI_PASS
else
    SSH="ssh"
    RSYNC_RSH="ssh"
fi

echo ""
echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}${BLUE}Building & deploying to ${CYAN}${PI_USER}@${PI_HOST}${NC}"
echo ""

# Step 1: Install build dependencies
echo -e "  ${YELLOW}[1/6]${NC} Installing build dependencies..."
$SSH "$PI_USER@$PI_HOST" "sudo apt-get update -qq && sudo apt-get install -y -qq cmake g++ libmosquitto-dev > /dev/null 2>&1"
echo -e "  ${GREEN}  done${NC}"

# Step 2: Copy source and build on Pi
echo -e "  ${YELLOW}[2/6]${NC} Copying source..."
$SSH "$PI_USER@$PI_HOST" "rm -rf $REMOTE_BUILD_DIR && mkdir -p $REMOTE_BUILD_DIR"
rsync -az --exclude='build*' -e "$RSYNC_RSH" "$PROJECT_ROOT/" "$PI_USER@$PI_HOST:$REMOTE_BUILD_DIR/"
echo -e "  ${GREEN}  done${NC}"

echo -e "  ${YELLOW}[3/6]${NC} Building on Raspberry Pi..."
$SSH "$PI_USER@$PI_HOST" "cd $REMOTE_BUILD_DIR && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -1 && cmake --build build --parallel 2>&1 | tail -1"
echo -e "  ${GREEN}  done${NC}"

# Step 4: Install binary
echo -e "  ${YELLOW}[4/6]${NC} Installing binary..."
$SSH "$PI_USER@$PI_HOST" "sudo mkdir -p $REMOTE_DIR && sudo cp $REMOTE_BUILD_DIR/build/wmbus-gateway $REMOTE_DIR/ && sudo chmod +x $REMOTE_DIR/wmbus-gateway"
echo -e "  ${GREEN}  done${NC}"

# Build argument list
ARGS="--port $SERIAL_PORT --baud $BAUD_RATE --mqtt-host $MQTT_HOST --mqtt-port $MQTT_PORT --topic $MQTT_TOPIC"
if [ -n "${GATEWAY_ID:-}" ]; then
    ARGS="$ARGS --gateway-id $GATEWAY_ID"
fi
if [ "${ACTIVATE:-false}" = "true" ]; then
    ARGS="$ARGS --activate"
fi

# Step 5: Generate and install systemd service
echo -e "  ${YELLOW}[5/6]${NC} Installing systemd service..."
cat <<EOF | $SSH "$PI_USER@$PI_HOST" "sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null"
[Unit]
Description=WMBus Gateway (Wurth Metis-II)
After=network.target

[Service]
Type=simple
ExecStart=${REMOTE_DIR}/wmbus-gateway ${ARGS}
WorkingDirectory=${REMOTE_DIR}
Restart=always
RestartSec=5
User=${PI_USER}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
echo -e "  ${GREEN}  done${NC}"

# Step 6: Enable and start
echo -e "  ${YELLOW}[6/6]${NC} Starting service..."
$SSH "$PI_USER@$PI_HOST" "sudo systemctl daemon-reload && sudo systemctl enable ${SERVICE_NAME} && sudo systemctl restart ${SERVICE_NAME}"
echo -e "  ${GREEN}  done${NC}"

# Cleanup build dir
$SSH "$PI_USER@$PI_HOST" "rm -rf $REMOTE_BUILD_DIR"

echo ""
echo -e "  ${DIM}─────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}${BOLD}Deployment complete!${NC}"
echo ""
echo -e "  ${DIM}Status:${NC}  ssh $PI_USER@$PI_HOST sudo systemctl status $SERVICE_NAME"
echo -e "  ${DIM}Logs:${NC}    ssh $PI_USER@$PI_HOST sudo journalctl -u $SERVICE_NAME -f"
echo ""
