#!/usr/bin/env bash
# ==============================================================================
# Infrastructure Diagnostics Script
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   ServerLab Infrastructure Diagnostic Report  ${NC}"
echo -e "${BLUE}===============================================${NC}"

echo -e "\n${YELLOW}1. System Memory & Swap:${NC}"
free -h

echo -e "\n${YELLOW}2. Storage Usage:${NC}"
df -h / /opt 2>/dev/null || df -h /

echo -e "\n${YELLOW}3. Active Network Ports (Listening):${NC}"
ss -tulpn | grep -E ':(80|443|81|1055|3306|10000|22|24061)' || ss -tulpn

echo -e "\n${YELLOW}4. Docker Containers Status:${NC}"
if command -v docker >/dev/null 2>&1; then
  docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
  echo -e "${RED}Docker is not installed.${NC}"
fi

echo -e "\n${YELLOW}5. TUN Device Check:${NC}"
if [ -e /dev/net/tun ]; then
  echo -e "${GREEN}/dev/net/tun exists (Kernel TUN enabled)${NC}"
else
  echo -e "${RED}/dev/net/tun is missing (Userspace mode REQUIRED for Tailscale)${NC}"
fi

echo -e "\n${YELLOW}6. Checking Cloudflare Tunnel Container:${NC}"
if docker ps --format '{{.Names}}' | grep -q 'infra-cloudflared'; then
  docker logs --tail 10 infra-cloudflared
else
  echo "infra-cloudflared is not currently running."
fi

echo -e "\n${YELLOW}7. Checking Tailscale Container:${NC}"
if docker ps --format '{{.Names}}' | grep -q 'infra-tailscale'; then
  docker logs --tail 10 infra-tailscale
else
  echo "infra-tailscale is not currently running."
fi

echo -e "\n${BLUE}===============================================${NC}"
echo -e "${GREEN}Diagnostic complete.${NC}"
