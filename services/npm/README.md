# Nginx Proxy Manager (NPM) Service

## Purpose
Acts as the central reverse proxy and SSL gateway for all services and applications on the server. By integrating with Cloudflare Tunnel, NPM manages all domain, subdomain, and subpath routing through a user-friendly web interface.

## Directory Structure
- Compose File: `/opt/infra/services/npm/compose.yaml`
- Environment: `/opt/infra/services/npm/.env`
- Data Store: `/opt/app-data/npm/data/` (SQLite DB & configs)
- SSL Store: `/opt/app-data/npm/letsencrypt/`

## Resource Footprint
- Runs with embedded **SQLite**, consuming **< 70MB RAM** (ideal for 1 GB RAM LXC containers).

## Quick Start

### 1. Requirements
- Ensure host Apache is disabled if binding to port 80/443 (`sudo systemctl stop apache2 && sudo systemctl disable apache2`).
- Storage directories created:
  ```bash
  mkdir -p /opt/app-data/npm/data /opt/app-data/npm/letsencrypt
  ```

### 2. Configure Environment
In `/opt/infra/services/npm/`:
```bash
cp .env.example .env
nano .env
```

### 3. Start the Service
```bash
# Ensure shared Docker bridge network exists
docker network create infra_network 2>/dev/null || true

# Run NPM from its directory
cd /opt/infra/services/npm
docker compose up -d
```

### 4. Access Administration Dashboard
Because port 81 is bound to `127.0.0.1:81` for security, access it via:
- **SSH Port Forwarding**: `ssh -L 8181:localhost:81 user@host-ip` -> open `http://localhost:8181`
- **Tailscale**: Connect via Tailscale SOCKS5 proxy or Tailscale browser configuration.

### 5. Default Login
- **Email**: `admin@example.com`
- **Password**: `changeme`
- *Action*: Update these credentials immediately upon first login.
