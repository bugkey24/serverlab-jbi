#!/usr/bin/env bash
# ==============================================================================
# Infrastructure Initialization & Setup Script
# Target: Debian 12 / TurnKey Linux LXC / Clean Docker Host
# Standard: /opt/app-data/{app-or-service}/{component-or-service}
# ==============================================================================

set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Campus Hosting Infrastructure Setup ===${NC}"

# Check for root / sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root or with sudo.${NC}"
  exit 1
fi

APP_DATA_DIR="/opt/app-data"
APPS_DIR="/opt/apps"
INFRA_DIR="/opt/infra"

echo -e "${BLUE}Creating standard directory hierarchy (/opt/app-data/{app-or-service}/{component})...${NC}"
mkdir -p "${APP_DATA_DIR}/cloudflared/config"
mkdir -p "${APP_DATA_DIR}/tailscale/state"
mkdir -p "${APP_DATA_DIR}/npm/data"
mkdir -p "${APP_DATA_DIR}/npm/letsencrypt"
mkdir -p "${APPS_DIR}"

echo -e "${GREEN}Directories successfully initialized:${NC}"
echo "  - Cloudflare Tunnel: ${APP_DATA_DIR}/cloudflared/config"
echo "  - Tailscale:         ${APP_DATA_DIR}/tailscale/state"
echo "  - NPM Data:          ${APP_DATA_DIR}/npm/data"
echo "  - NPM SSL:           ${APP_DATA_DIR}/npm/letsencrypt"
echo "  - Applications:      ${APPS_DIR}/"

# Prepare per-service .env files if not already present
for svc in cloudflared npm tailscale; do
  svc_dir="${INFRA_DIR}/services/${svc}"
  if [ -d "${svc_dir}" ]; then
    if [ ! -f "${svc_dir}/.env" ] && [ -f "${svc_dir}/.env.example" ]; then
      echo -e "${YELLOW}Creating ${svc}/.env from template...${NC}"
      cp "${svc_dir}/.env.example" "${svc_dir}/.env"
    fi
  fi
done

# Check if Apache is installed and running
if systemctl is-active --quiet apache2 2>/dev/null; then
  echo -e "${YELLOW}Detected active Apache service on host.${NC}"
  read -p "Do you want to stop and disable Apache to free port 80/443 for NPM? (y/N): " -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    systemctl stop apache2
    systemctl disable apache2
    echo -e "${GREEN}Apache stopped and disabled.${NC}"
  else
    echo -e "${YELLOW}Retaining Apache. Note: NPM might fail to bind host port 80.${NC}"
  fi
fi

# Create shared Docker Network
if command -v docker >/dev/null 2>&1; then
  if ! docker network ls --format '{{.Name}}' | grep -q '^infra_network$'; then
    echo -e "${BLUE}Creating Docker network 'infra_network'...${NC}"
    docker network create infra_network
    echo -e "${GREEN}Network 'infra_network' created.${NC}"
  else
    echo -e "${GREEN}Docker network 'infra_network' already exists.${NC}"
  fi
else
  echo -e "${RED}Docker is not installed! Please install Docker before proceeding.${NC}"
  exit 1
fi

echo -e "${GREEN}=== Setup completed successfully! ===${NC}"
echo -e "Next steps:"
echo -e "  1. Configure .env in each service directory under ${INFRA_DIR}/services/"
echo -e "  2. Start services independently as needed:"
echo -e "     - ${YELLOW}cd ${INFRA_DIR}/services/npm && docker compose up -d${NC}"
echo -e "     - ${YELLOW}cd ${INFRA_DIR}/services/cloudflared && docker compose up -d${NC}"
echo -e "     - ${YELLOW}cd ${INFRA_DIR}/services/tailscale && docker compose up -d${NC}"
