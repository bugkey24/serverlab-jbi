# Tailscale Userspace Service

## Purpose
Runs Tailscale in **Userspace Networking Mode** using Go's internal `netstack`. This allows unprivileged LXC containers to join a private Tailnet without requiring `/dev/net/tun` or kernel-level network privileges.

## Directory Structure
- Compose File: `/opt/infra/services/tailscale/compose.yaml`
- Environment: `/opt/infra/services/tailscale/.env`
- Data Store: `/opt/app-data/tailscale/state/`

## Quick Start

### 1. Requirements
- A valid Tailscale Auth Key (`tskey-auth-...`) from the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).

### 2. Configure Environment
In `/opt/infra/services/tailscale/`:
```bash
cp .env.example .env
nano .env
```
Set values:
```bash
APP_DATA_DIR=/opt/app-data
TAILSCALE_AUTHKEY=tskey-auth-xxxxxx
TAILSCALE_HOSTNAME=campus-lxc-node
TAILSCALE_PORT=1055
```

### 3. Start the Service
```bash
# Ensure shared Docker bridge network exists
docker network create infra_network 2>/dev/null || true

# Run Tailscale from its directory
cd /opt/infra/services/tailscale
docker compose up -d
```

### 4. Verification
```bash
docker compose logs -f
```
When running, you will see `Tailscale is up and running!`.

## Usage
- **Tailscale SSH**: From another machine in your Tailnet:
  ```bash
  tailscale ssh campus-lxc-node
  ```
- **SOCKS5 Proxy**:
  ```bash
  curl --socks5-hostname localhost:1055 https://api.ipify.org
  ```
