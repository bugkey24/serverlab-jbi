# Cloudflare Tunnel Service

## Purpose
Runs Cloudflare's lightweight connector daemon (`cloudflared`). It establishes an outbound-only, encrypted tunnel to Cloudflare Edge data centers, granting public access to internal services without opening firewall ports or acquiring a static public IP.

## Directory Structure
- Compose File: `/opt/infra/services/cloudflared/compose.yaml`
- Environment: `/opt/infra/services/cloudflared/.env`
- Runtime Storage: `/opt/app-data/cloudflared/config`

## Quick Start

### 1. Requirements
- A Cloudflare account with a domain registered or transferred to Cloudflare DNS.
- A Tunnel Token created in **Cloudflare Zero Trust** (`Networks` -> `Tunnels`).

### 2. Configure Environment
In `/opt/infra/services/cloudflared/`:
```bash
cp .env.example .env
nano .env
```
Set your tunnel token:
```ini
APP_DATA_DIR=/opt/app-data
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...
```

### 3. Start the Service
```bash
# Ensure shared Docker bridge network exists
docker network create infra_network 2>/dev/null || true

# Run the service from its directory
cd /opt/infra/services/cloudflared
docker compose up -d
```

### 4. Verification
```bash
docker compose logs -f
```
Output should show successful connections to Cloudflare edge data centers (`INF Connection registered ...`).

## Architecture Recommendation
Route a wildcard hostname (e.g. `*.yourdomain.com`) in the Cloudflare Zero Trust Tunnel dashboard to:
- Service: `HTTP`
- URL: `npm:80`

This delegates all internal routing decisions to **Nginx Proxy Manager**!
