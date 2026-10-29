#!/usr/bin/env bash
# ==============================================================================
# Reset & Teardown ServerLab Infrastructure (Clean Slate Tool)
# Restores TurnKey GNU/Linux 18 / Debian 12 LXC to its fresh factory state
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}====================================================================${NC}"
echo -e "${RED}      SERVERLAB INFRASTRUCTURE RESET & CLEAN-SLATE UTILITY         ${NC}"
echo -e "${RED}====================================================================${NC}"
echo -e "This utility will:"
echo -e "  1. Stop & remove all running Docker containers (Pulse, NPM, Cloudflared)."
echo -e "  2. Purge persistent application and infrastructure volume data."
echo -e "  3. Stop, unauthenticate, and uninstall Native Host Tailscale."
echo -e "  4. Reset and restore default native Apache2 & native MariaDB on host."
echo -e "  5. Clean Webmin webroot (/var/www/laravel) for Track 1 tutorial."
echo -e "${RED}====================================================================${NC}"

read -p "Are you sure you want to completely reset this server? (type 'yes' to proceed): " -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Teardown aborted by user.${NC}"
    exit 0
fi

# ------------------------------------------------------------------------------
# 1. Stop & Remove All Docker Containers
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[1/5] Stopping and removing all Docker containers & networks...${NC}"

# Demo application
if [ -d "/opt/infra/examples/demo-laravel-app" ]; then
    cd /opt/infra/examples/demo-laravel-app
    docker compose down -v 2>/dev/null || true
fi

# Cloudflare Tunnel
if [ -d "/opt/infra/services/cloudflared" ]; then
    cd /opt/infra/services/cloudflared
    docker compose down -v 2>/dev/null || true
fi

# Nginx Proxy Manager
if [ -d "/opt/infra/services/npm" ]; then
    cd /opt/infra/services/npm
    docker compose down -v 2>/dev/null || true
fi

# Kill any leftover orphan containers
ORPHANS=$(docker ps -aq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    docker rm -f $ORPHANS 2>/dev/null || true
fi

# Remove infra network
docker network rm infra_network 2>/dev/null || true
echo -e "${GREEN}--> All Docker containers and networks cleaned.${NC}"

# ------------------------------------------------------------------------------
# 2. Purge Persistent App & Service Storage (/opt/app-data)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[2/5] Purging persistent data volumes (/opt/app-data)...${NC}"
rm -rf /opt/app-data/npm/data/*
rm -rf /opt/app-data/npm/letsencrypt/*
rm -rf /opt/app-data/cloudflared/config/*
rm -rf /opt/app-data/demo-laravel-app/database/*
rm -rf /opt/app-data/demo-laravel-app/storage/*
echo -e "${GREEN}--> Persistent data directories emptied.${NC}"

# ------------------------------------------------------------------------------
# 3. Teardown Native Host Tailscale
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[3/5] Tearing down Native Host Tailscale...${NC}"
if command -v tailscale &>/dev/null; then
    tailscale logout 2>/dev/null || true
fi

if systemctl is-active --quiet tailscaled 2>/dev/null; then
    systemctl stop tailscaled || true
fi

systemctl disable tailscaled 2>/dev/null || true
rm -rf /etc/systemd/system/tailscaled.service.d
rm -f /etc/default/tailscaled
rm -rf /var/lib/tailscale/*
systemctl daemon-reload

apt-get purge -y tailscale tailscale-archive-keyring 2>/dev/null || true
rm -f /etc/apt/sources.list.d/tailscale.list
rm -f /usr/share/keyrings/tailscale-archive-keyring.gpg
echo -e "${GREEN}--> Tailscale completely removed and unauthenticated.${NC}"

# ------------------------------------------------------------------------------
# 4. Restore Default Host Apache2 & MariaDB
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[4/5] Restoring default native Apache2 and MariaDB services...${NC}"
systemctl unmask apache2 2>/dev/null || true
systemctl enable apache2 2>/dev/null || true
systemctl restart apache2 2>/dev/null || true

systemctl unmask mariadb 2>/dev/null || true
systemctl enable mariadb 2>/dev/null || true
systemctl restart mariadb 2>/dev/null || true

echo -e "Testing host ports:"
ss -tulpn | grep -E ':(80|3306)' || true
echo -e "${GREEN}--> Native Apache2 and MariaDB are ACTIVE and listening on host.${NC}"

# ------------------------------------------------------------------------------
# 5. Clean Webmin Document Root (/var/www/laravel)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[5/5] Resetting Webmin /var/www/laravel target directory...${NC}"
mkdir -p /var/www/laravel/public
cat << 'EOF' > /var/www/laravel/public/index.php
<?php
echo "<h1>Welcome to TurnKey LAMP (Clean State)</h1>";
echo "<p>Ready for Track 1: Webmin & Adminer Deployment Tutorial.</p>";
EOF

chown -R www-data:www-data /var/www/laravel
chmod -R 755 /var/www/laravel

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}          SERVER RESET COMPLETE! CLEAN SLATE RESTORED.              ${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Your LXC host is now back in its clean starting state:"
echo -e "  - Native Apache is serving http://192.168.11.16/ on port 80."
echo -e "  - Webmin is accessible on port 10000."
echo -e "  - Adminer is accessible on port 12322."
echo -e "  - Ready to record Tutorial Series Episode 1!"
echo -e "${GREEN}====================================================================${NC}"
