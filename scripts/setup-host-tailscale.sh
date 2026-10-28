#!/usr/bin/env bash
# ==============================================================================
# Setup Tailscale on Host (TurnKey GNU/Linux 18 / Debian 12)
# Enables Userspace Networking + Tailscale SSH directly on the host OS
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " Setting up Tailscale on Host OS (root@$(hostname))"
echo "=========================================================="

# 1. Stop and remove Docker-based tailscale if running
if [ -d "/opt/infra/services/tailscale" ]; then
    echo "[1/5] Checking Docker Tailscale container..."
    cd /opt/infra/services/tailscale
    if docker compose ps --services --filter "status=running" 2>/dev/null | grep -q "tailscale"; then
        echo "--> Stopping Docker-based tailscale to prevent port/name collision..."
        docker compose down
    fi
fi

# 2. Install Tailscale package via official repository
echo "[2/5] Installing Tailscale on Debian..."
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "--> Tailscale package is already installed."
fi

# 3. Configure systemd daemon to run in userspace networking mode
echo "[3/5] Configuring /etc/default/tailscaled for unprivileged LXC..."
cat << 'EOF' > /etc/default/tailscaled
# Configuration for tailscaled on unprivileged LXC
# Netstack userspace networking (no /dev/net/tun needed)
# SOCKS5 & HTTP proxies bound on localhost:1055 for local applications
FLAGS="--tun=userspace-networking --socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055"
EOF

# 4. Reload and restart systemd service
echo "[4/5] Reloading and starting systemd tailscaled..."
systemctl daemon-reload
systemctl enable tailscaled
systemctl restart tailscaled

# 5. Check service status
sleep 2
if systemctl is-active --quiet tailscaled; then
    echo "--> tailscaled service is ACTIVE!"
else
    echo "--> ERROR: tailscaled failed to start. Check: journalctl -u tailscaled -e"
    exit 1
fi

echo "=========================================================="
echo "[5/5] READY TO AUTHENTICATE!"
echo ""
echo "To connect this host to your Tailnet with SSH enabled, run:"
echo ""
echo "  sudo tailscale up --ssh --hostname=campus-lxc-node"
echo ""
echo "Or headlessly with your auth key:"
echo "  sudo tailscale up --authkey=tskey-auth-xxxx --ssh --hostname=campus-lxc-node"
echo "=========================================================="
