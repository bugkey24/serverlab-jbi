#!/usr/bin/env bash
# ==============================================================================
# Fast Reset & Preparation Script for Tutorial 1 (Webmin Track 1)
# Target: TurnKey GNU/Linux 18 (Debian 12) LXC Host (jbi24061)
# Use Case: Run before recording Episode 1, or between recording takes
#           to instantly reset the server to the exact starting state
#           without purging system packages or Docker Engine.
# ==============================================================================
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BOLD}${BLUE}       TUTORIAL 1 PREPARATION & FAST RESET (TAKE RESET)             ${NC}"
echo -e "${BLUE}====================================================================${NC}"
echo -e "This script resets the server to the exact clean state needed for"
echo -e "Tutorial 1 (Webmin & Adminer Deployment):"
echo -e "  • Cleans /var/www/laravel and restores the initial TurnKey placeholder"
echo -e "  • Drops the 'db_serverlab' database in MariaDB (ready for Adminer import)"
echo -e "  • Ensures Native Apache2 & MariaDB are running on ports 80 & 3306"
echo -e "  • Stops Docker containers to avoid port conflicts with Apache"
echo -e "  • Cleans temporary upload archives (.zip, .tar.gz)"
echo -e "${BLUE}====================================================================${NC}\n"

# Verify root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] This script must be run as root or with sudo.${NC}"
  exit 1
fi

# Optional non-interactive mode with -y or --yes
FORCE_YES=false
for arg in "$@"; do
  if [ "$arg" == "-y" ] || [ "$arg" == "--yes" ]; then
    FORCE_YES=true
  fi
done

if [ "$FORCE_YES" = false ]; then
  read -p "Reset server state for Tutorial 1? (y/N): " -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}Aborted by user.${NC}"
    exit 0
  fi
fi

# ------------------------------------------------------------------------------
# 1. Stop Any Conflicting Docker Stacks
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[1/5] Ensuring no Docker containers conflict with native ports...${NC}"
if command -v docker >/dev/null 2>&1; then
  # Stop containers that might bind 80, 443, or 3306
  RUNNING=$(docker ps -q 2>/dev/null || true)
  if [ -n "$RUNNING" ]; then
    echo -e "  ${YELLOW}Stopping running Docker containers...${NC}"
    docker stop $RUNNING >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓ Docker containers stopped.${NC}"
  else
    echo -e "  ${GREEN}✓ No active Docker containers running.${NC}"
  fi
else
  echo -e "  ${GREEN}✓ Docker not present (no container conflicts).${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Reset Native Apache2 Service
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[2/5] Restoring Native Apache2 Web Server...${NC}"
systemctl unmask apache2 2>/dev/null || true
systemctl enable apache2 2>/dev/null || true
systemctl restart apache2 2>/dev/null || true

if systemctl is-active --quiet apache2; then
  echo -e "  ${GREEN}✓ Apache2 is ACTIVE and listening on Port 80.${NC}"
else
  echo -e "  ${RED}✗ Failed to start Apache2. Please check 'journalctl -xeu apache2'.${NC}"
fi

# ------------------------------------------------------------------------------
# 3. Reset Native MariaDB Service & Drop Demo Database
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[3/5] Restoring Native MariaDB & Cleaning Demo Database...${NC}"
systemctl unmask mariadb 2>/dev/null || true
systemctl enable mariadb 2>/dev/null || true
systemctl restart mariadb 2>/dev/null || true

if systemctl is-active --quiet mariadb; then
  echo -e "  ${GREEN}✓ MariaDB is ACTIVE and listening on Port 3306.${NC}"
  
  # Drop db_serverlab if it was imported during a previous take
  if mariadb -e "DROP DATABASE IF EXISTS db_serverlab;" 2>/dev/null; then
    echo -e "  ${GREEN}✓ Dropped existing 'db_serverlab' database (ready for fresh Adminer import).${NC}"
  else
    # Fallback to mysql command if mariadb alias isn't present
    mysql -e "DROP DATABASE IF EXISTS db_serverlab;" 2>/dev/null || true
    echo -e "  ${GREEN}✓ Executed cleanup for 'db_serverlab'.${NC}"
  fi
else
  echo -e "  ${RED}✗ MariaDB is not running. Please check 'journalctl -xeu mariadb'.${NC}"
fi

# ------------------------------------------------------------------------------
# 4. Clean Webmin Document Root (/var/www/laravel)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[4/5] Resetting Webmin Filemin Webroot (/var/www/laravel)...${NC}"

# Remove any previously extracted application or uploaded archive
if [ -d "/var/www/laravel" ]; then
  # Preserve /var/www/laravel directory itself, but clean contents
  rm -rf /var/www/laravel/*
  rm -rf /var/www/laravel/.[!.]* 2>/dev/null || true
else
  mkdir -p /var/www/laravel
fi

mkdir -p /var/www/laravel/public

# Place the initial default TurnKey placeholder index.php
cat << 'EOF' > /var/www/laravel/public/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TurnKey LAMP - ServerLab Ready</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: #1e293b; padding: 2.5rem; border-radius: 12px; border: 1px solid #334155; max-width: 540px; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
        h1 { color: #38bdf8; margin-top: 0; font-size: 1.75rem; }
        p { color: #94a3b8; font-size: 1rem; line-height: 1.6; }
        .badge { display: inline-block; background: #0369a1; color: #e0f2fe; padding: 0.35rem 0.75rem; border-radius: 9999px; font-size: 0.85rem; font-weight: 600; margin-bottom: 1rem; }
        .footer { font-size: 0.8rem; color: #64748b; margin-top: 1.5rem; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">Ready for Tutorial 1</span>
        <h1>TurnKey LAMP Stack</h1>
        <p>This container is primed for <strong>Track 1: Zero-CLI Webmin & Adminer Deployment</strong>.</p>
        <p>Upload your application package via Webmin Filemin to <code>/var/www/laravel</code> to begin.</p>
        <div class="footer">TurnKey GNU/Linux 18 (Debian 12) • Poliwangi ServerLab</div>
    </div>
</body>
</html>
EOF

# Set proper ownership and permissions
chown -R www-data:www-data /var/www/laravel
chmod -R 755 /var/www/laravel

echo -e "  ${GREEN}✓ Restored clean placeholder at /var/www/laravel/public/index.php${NC}"
echo -e "  ${GREEN}✓ Set ownership to www-data:www-data with 755 permissions.${NC}"

# ------------------------------------------------------------------------------
# 5. Clean Upload Artifact Cache in Common Directories
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[5/5] Cleaning temporary upload archives...${NC}"
rm -f /root/*.zip /root/*.tar.gz /root/*.sql 2>/dev/null || true
rm -f /tmp/*.zip /tmp/*.tar.gz /tmp/*.sql 2>/dev/null || true
echo -e "  ${GREEN}✓ Temporary archives cleaned from /root and /tmp.${NC}"

# ------------------------------------------------------------------------------
# Summary Verification
# ------------------------------------------------------------------------------
echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}        TUTORIAL 1 ENVIRONMENT IS PRIMED & READY!           ${NC}"
echo -e "${GREEN}====================================================================${NC}"
echo -e "Live Verification Status:"
echo -e "  • Apache Web Server:  ${GREEN}$(systemctl is-active apache2)${NC} (Port 80)"
echo -e "  • MariaDB Database:   ${GREEN}$(systemctl is-active mariadb)${NC} (Port 3306)"
echo -e "  • Webmin Filemin:     Ready at /var/www/laravel"
echo -e "  • Adminer UI:         Accessible at port 12322"
echo -e "  • Campus Subpath:     https://tajbi.poliwangi.ac.id/jbi24061/"
echo -e "\nYou are completely ready to hit record on Episode 1! 🎬"
echo -e "${GREEN}====================================================================${NC}"
