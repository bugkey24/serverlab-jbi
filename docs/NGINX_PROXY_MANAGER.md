# Nginx Proxy Manager (NPM) & Routing Architecture

## 1. Role in the Architecture

In this infrastructure setup, **Nginx Proxy Manager (NPM)** serves as the central traffic switchboard:
1. **Consolidated Edge Entry**: Receives all incoming HTTP/HTTPS traffic forwarded from the Cloudflare Tunnel (`infra-cloudflared`).
2. **Dynamic Multi-App Routing**: Allows launching multiple isolated applications in `/opt/apps/*` and mapping custom subdomains (e.g. `api.domain.com`, `admin.domain.com`, `shop.domain.com`) or subpaths (`/app1`, `/app2`) using a clean, web-based UI.
3. **Internal SSL & Custom Directives**: Manages SSL certificates, custom HTTP headers, Websockets support, and security rules without manual Nginx configuration edits.
4. **Host Port Agnostic**: Because traffic enters via Cloudflare Tunnel over Docker internal networks, NPM does not strictly require exclusive ownership of host port 80/443 if legacy host services (like Apache) must remain active during migration.

---

## 2. Low-Resource Optimization for 1 GB RAM LXCs

By default, many NPM guides deploy a companion MariaDB/MySQL container. Running a dedicated MySQL instance consumes 250MB–450MB of RAM—nearly **half** of a 1 GB RAM container limit.

**Optimization**:
NPM supports an embedded **SQLite** database mode. Running NPM with SQLite drops memory consumption to approximately **40MB–70MB**, leaving more than 85% of system memory free for your actual applications (Laravel, PHP-FPM, Redis, etc.).

---

## 3. Docker Service Definition (`services/npm/compose.yaml`)

```yaml
name: infra-npm

services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: infra-npm
    restart: unless-stopped
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
      - "127.0.0.1:${NPM_ADMIN_PORT:-81}:81"
    environment:
      - DISABLE_IPV6=true
      - TZ=${TZ:-Asia/Jakarta}
    volumes:
      - ${APP_DATA_DIR:-/opt/app-data}/infra/npm/data:/data
      - ${APP_DATA_DIR:-/opt/app-data}/infra/npm/letsencrypt:/etc/letsencrypt
    networks:
      - infra_network

networks:
  infra_network:
    name: infra_network
    external: true
```

> [!TIP]
> Notice the admin port binding: `"127.0.0.1:81:81"`. This prevents the administrative dashboard from being exposed to the public internet or campus LAN. You can access it securely via an SSH tunnel or via Tailscale SOCKS5 proxy.

---

## 4. Setup & Initial Configuration

### Step 1: Initialize Storage Directories
```bash
mkdir -p /opt/app-data/infra/npm/data /opt/app-data/infra/npm/letsencrypt
```

### Step 2: Configure Environment
In `/opt/infra/services/npm/`:
```bash
cp .env.example .env
nano .env
```

### Step 3: Start NPM Service
```bash
cd /opt/infra/services/npm
docker compose up -d
docker compose logs -f
```

### Step 4: Access Admin Dashboard
- **URL**: `http://localhost:81` (via local browser with Tailscale SOCKS5 or SSH port forwarding `ssh -L 8181:localhost:81 user@host`).
- **Default Credentials**:
  - Email: `admin@example.com`
  - Password: `changeme`
- **Important**: Immediately change the email and password upon first login!

---

## 5. Adding a Proxy Host for an Application

To route traffic to an app running in `/opt/apps/my-app`:

1. **Ensure Shared Network**: Ensure the app's `compose.yaml` connects to the external network `infra_network`.
   ```yaml
   networks:
     infra_network:
       external: true
   ```
2. **In NPM Admin Dashboard**:
   - Go to **Hosts** -> **Proxy Hosts** -> **Add Proxy Host**.
   - **Domain Names**: `my-app.yourdomain.com`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `<container_name>` (e.g. `myapp-web`)
   - **Forward Port**: `80` (or the app's internal port)
   - Enable: **Block Common Exploits**, **Websockets Support** (if needed).
3. **SSL Tab**:
   - If using Cloudflare Tunnel, Cloudflare terminates SSL at the edge. You can select **None** or request a Let's Encrypt cert if Strict Full SSL mode is desired in Cloudflare.

---

## 6. Troubleshooting

#### 1. Port 80/443 conflict on startup (`bind: address already in use`)
- **Cause**: Apache2 from TurnKey LAMP is still active on the host.
- **Resolution**:
  - Check what is listening: `sudo ss -tulpn | grep -E ':(80|443)'`
  - Stop Apache: `sudo systemctl stop apache2 && sudo systemctl disable apache2`
  - Or, if you must keep Apache running on the host, set `HTTP_PORT=8080` in `.env`. Since Cloudflare Tunnel routes directly inside Docker, host port 80 is not required for tunnel ingress!

#### 2. 502 Bad Gateway when visiting the domain
- **Cause**: NPM cannot reach the destination container.
- **Fix**: Verify both NPM and the application container are on `infra_network` using `docker network inspect infra_network`. Verify the application container is healthy and responding.
