#!/usr/bin/env bash
# ==============================================================================
# Post-Tutorial 1 System Configuration & Transition Script
# Target: TurnKey GNU/Linux 18 (Debian 12) LXC Host (jbi24061)
# Purpose: Prepares system, Docker environment, directories, and networks
#          for Tutorial 2 (Tailscale), Tutorial 3 (NPM + Cloudflare), and Tutorial 4 (Docker VPS)
# ==============================================================================
set -euo pipefail

# Styling & colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BOLD}${BLUE}   POST-TUTORIAL 1 SYSTEM ADJUSTMENTS & INFRASTRUCTURE PREPARATION  ${NC}"
echo -e "${BLUE}====================================================================${NC}"
echo -e "This script adjusts the server after Tutorial 1 (Webmin Track 1) to prepare"
echo -e "for Tutorial 2 (Tailscale), Tutorial 3 (Cloudflare Tunnel + NPM), and"
echo -e "Tutorial 4 (Containerized Laravel VPS Stack)."
echo -e "${BLUE}====================================================================${NC}\n"

# Verify root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] This script must be run as root or with sudo.${NC}"
  exit 1
fi

# Detect workspace / root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Inspect & Verify Tutorial 1 State
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/6] Inspecting Tutorial 1 Deployment State...${NC}"

if [ -f "/var/www/laravel/public/index.php" ]; then
  echo -e "  ${GREEN}✓ Found active Laravel deployment in /var/www/laravel/public${NC}"
  # Ensure storage and bootstrap permissions remain healthy
  chown -R www-data:www-data /var/www/laravel/storage /var/www/laravel/bootstrap/cache 2>/dev/null || true
  chmod -R 775 /var/www/laravel/storage /var/www/laravel/bootstrap/cache 2>/dev/null || true
  echo -e "  ${GREEN}✓ Enforced www-data:775 permissions on /var/www/laravel storage/cache.${NC}"
else
  echo -e "  ${YELLOW}! No deployment found at /var/www/laravel/public (skipping permission fix).${NC}"
fi

# ------------------------------------------------------------------------------
# 2. System Dependency Check & Docker Environment Setup
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[2/6] Verifying System Dependencies & Docker Runtime...${NC}"

# Update package lists if necessary
export DEBIAN_FRONTEND=noninteractive

PACKAGES_TO_INSTALL=()
for pkg in curl git iptables ca-certificates gnupg; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    PACKAGES_TO_INSTALL+=("$pkg")
  fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
  echo -e "  ${YELLOW}Installing missing base packages: ${PACKAGES_TO_INSTALL[*]}...${NC}"
  apt-get update -y
  apt-get install -y --no-install-recommends "${PACKAGES_TO_INSTALL[@]}"
else
  echo -e "  ${GREEN}✓ Base system utilities (curl, git, iptables) are installed.${NC}"
fi

# Docker Engine & Docker Compose Plugin check
if ! command -v docker >/dev/null 2>&1; then
  echo -e "  ${YELLOW}Docker is not detected. Installing standard Docker Engine & Compose...${NC}"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -y
  apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  echo -e "  ${GREEN}✓ Docker Engine successfully installed and activated.${NC}"
else
  echo -e "  ${GREEN}✓ Docker Engine is present: $(docker --version)${NC}"
  systemctl enable --now docker 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 3. Create Persistent Ingress & Storage Directories
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[3/6] Initializing Standard Persistent Storage Directories...${NC}"

# Standard location: /opt/app-data/{service}/{component}
mkdir -p /opt/app-data/npm/data
mkdir -p /opt/app-data/npm/letsencrypt
mkdir -p /opt/app-data/cloudflared/config
mkdir -p /opt/app-data/demo-laravel-app/mariadb
mkdir -p /opt/app-data/demo-laravel-app/storage
mkdir -p /opt/apps

echo -e "  ${GREEN}✓ /opt/app-data/npm/ (data & letsencrypt)${NC}"
echo -e "  ${GREEN}✓ /opt/app-data/cloudflared/config/${NC}"
echo -e "  ${GREEN}✓ /opt/app-data/demo-laravel-app/ (mariadb & storage)${NC}"

# ------------------------------------------------------------------------------
# 4. Provision Shared Docker Bridge Network ('infra_network')
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[4/6] Creating Shared Docker Ingress Network...${NC}"

if ! docker network ls --format '{{.Name}}' | grep -q '^infra_network$'; then
  docker network create infra_network
  echo -e "  ${GREEN}✓ Docker network 'infra_network' created successfully.${NC}"
else
  echo -e "  ${GREEN}✓ Docker network 'infra_network' is already present.${NC}"
fi

# ------------------------------------------------------------------------------
# 5. Environment Template Preparation
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[5/6] Preparing Infrastructure & Service Environment Files...${NC}"

# Cloudflare Tunnel .env
CF_DIR="${INFRA_ROOT}/services/cloudflared"
if [ -d "${CF_DIR}" ]; then
  if [ ! -f "${CF_DIR}/.env" ] && [ -f "${CF_DIR}/.env.example" ]; then
    cp "${CF_DIR}/.env.example" "${CF_DIR}/.env"
    echo -e "  ${GREEN}✓ Created ${CF_DIR}/.env from template (ready for TUNNEL_TOKEN).${NC}"
  else
    echo -e "  ${BLUE}• ${CF_DIR}/.env already exists.${NC}"
  fi
fi

# NPM .env
NPM_DIR="${INFRA_ROOT}/services/npm"
if [ -d "${NPM_DIR}" ]; then
  if [ ! -f "${NPM_DIR}/.env" ] && [ -f "${NPM_DIR}/.env.example" ]; then
    cp "${NPM_DIR}/.env.example" "${NPM_DIR}/.env"
    echo -e "  ${GREEN}✓ Created ${NPM_DIR}/.env from template.${NC}"
  else
    echo -e "  ${BLUE}• ${NPM_DIR}/.env already exists.${NC}"
  fi
fi

# Track 2 Demo App .env
DEMO_DIR="${INFRA_ROOT}/examples/demo-laravel-app"
if [ -d "${DEMO_DIR}" ]; then
  if [ ! -f "${DEMO_DIR}/.env" ] && [ -f "${DEMO_DIR}/.env.example" ]; then
    cp "${DEMO_DIR}/.env.example" "${DEMO_DIR}/.env"
    echo -e "  ${GREEN}✓ Created ${DEMO_DIR}/.env from template.${NC}"
  else
    echo -e "  ${BLUE}• ${DEMO_DIR}/.env already exists.${NC}"
  fi
fi

# ------------------------------------------------------------------------------
# 6. Port 80 Transition Strategy (Host Apache vs Containerized Ingress)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[6/6] Checking Port 80 & Host Apache Configuration...${NC}"

if systemctl is-active --quiet apache2 2>/dev/null; then
  echo -e "  ${YELLOW}Notice: Host Apache2 is currently running on Port 80 (serving Tutorial 1).${NC}"
  echo -e "  In Tutorial 3, Nginx Proxy Manager (NPM) will need Port 80 for edge routing."
  echo ""
  read -p "  Do you want to stop and disable Apache2 now to free Port 80 for NPM? (y/N): " -r TOGGLE_APACHE || TOGGLE_APACHE="n"
  if [[ "$TOGGLE_APACHE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    systemctl stop apache2
    systemctl disable apache2
    echo -e "  ${GREEN}✓ Apache2 stopped and disabled. Port 80 is now free for NPM.${NC}"
  else
    echo -e "  ${YELLOW}• Keeping Apache2 active for now. (Remember to stop it before Tutorial 3!)${NC}"
  fi
else
  echo -e "  ${GREEN}✓ Port 80 is free (Apache2 is inactive or disabled).${NC}"
fi

# Ensure executable permissions for setup-host-tailscale.sh
if [ -f "${INFRA_ROOT}/scripts/setup-host-tailscale.sh" ]; then
  chmod +x "${INFRA_ROOT}/scripts/setup-host-tailscale.sh"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}        SYSTEM CONFIGURATION & ADJUSTMENTS COMPLETE!        ${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Your server is now primed for the subsequent tutorial episodes:\n"
echo -e "  ${BOLD}Next -> Tutorial 2: Secure Host Tailscale (No-TUN Unprivileged LXC)${NC}"
echo -e "    Run: ${YELLOW}${INFRA_ROOT}/scripts/setup-host-tailscale.sh${NC}"
echo -e "    Then connect with: ${YELLOW}tailscale up --ssh --hostname=campus-lxc-node${NC}\n"
echo -e "  ${BOLD}Next -> Tutorial 3: Edge Ingress Gateway (Cloudflare + NPM)${NC}"
echo -e "    1. Insert your Tunnel Token into: ${YELLOW}${CF_DIR}/.env${NC}"
echo -e "    2. Start NPM: ${YELLOW}cd ${NPM_DIR} && docker compose up -d${NC}"
echo -e "    3. Start Tunnel: ${YELLOW}cd ${CF_DIR} && docker compose up -d${NC}\n"
echo -e "  ${BOLD}Next -> Tutorial 4: Track 2 Containerized Laravel VPS Stack${NC}"
echo -e "    Run: ${YELLOW}cd ${DEMO_DIR} && docker compose up -d --build${NC}"
echo -e "${GREEN}====================================================================${NC}"
