# Video Tutorial Series & Video Playlist Production Guide
## Modern Campus Hosting: From Restricted LXC to Multi-Tenant Cloud VPS

> **Series Premise**: How to take an unprivileged, shared academic Linux container (1 vCPU, 1 GB RAM, no public IP, no TUN device, restricted subpath) and step-by-step transform it into a modern, enterprise-grade cloud server running private mesh VPN, edge tunneling, reverse proxying, and production Laravel applications.

---

## 📺 Recommended Playlist Structure

| Episode | Title | Focus Area | Key Tools |
| :---: | :--- | :--- | :--- |
| **Ep. 1** | **Track 1: Zero-CLI Shared Hosting** | Deploying via Webmin & Adminer behind campus subpath | Webmin (`:10000`), Adminer (`:12322`), Apache |
| **Ep. 2** | **Native Tailscale in Unprivileged LXC** | Bypassing the no-TUN barrier for secure private SSH & Proxy | Tailscale, Userspace Netstack, systemd override |
| **Ep. 3** | **Cloudflare Tunnel & NPM Ingress Gateway** | Bypassing NAT firewalls & setting up wildcard routing | Cloudflare Tunnel, Docker, Nginx Proxy Manager |
| **Ep. 4** | **Track 2: Containerized Laravel VPS Mode** | Automated deployment, multi-stage build & zero-touch routing | Docker Compose, MariaDB, PHP 8.3-FPM, NPM |

---

## 🎬 Episode 1: Track 1 — Zero-CLI Shared Hosting Deployment

### Episode Objective
Demonstrate how a beginner student or developer with **zero command-line / SSH access** can deploy a complete Laravel application using only Webmin Filemin and Adminer GUI.

### Step-by-Step Script / Recording Workflow:
1. **Show Initial State**:
   - Open browser to `https://tajbi.poliwangi.ac.id/jbi24061/` (shows default TurnKey page).
   - Log into **Webmin** (`https://tajbi.poliwangi.ac.id:10000/`) and **Adminer** (`https://tajbi.poliwangi.ac.id:12322/`).
2. **Database Import via Adminer**:
   - Log into Adminer using `root` and default campus MariaDB password.
   - Create database: `db_serverlab`.
   - Click **SQL Command** or **Import**, upload `schema.sql`, and execute. Show the created `server_nodes` table.
3. **Upload Package via Webmin Filemin**:
   - Navigate to `/var/www/laravel`.
   - Upload pre-built `serverlab-pulse.zip` (or `serverlab-pulse.tar.gz`).
   - Extract archive. Move contents so `public/index.php` is directly under `/var/www/laravel/public`.
4. **Environment Configuration**:
   - Create `.env` inside `/var/www/laravel/`.
   - Set `APP_URL=https://tajbi.poliwangi.ac.id/jbi24061`.
   - Set `APP_PATH_PREFIX=jbi24061`.
   - Generate secure `APP_KEY` manually via PowerShell / OpenSSL without CLI.
   - Set permissions: Ensure `storage/` and `bootstrap/cache` are owned by `www-data`.
5. **Verify**:
   - Visit `https://tajbi.poliwangi.ac.id/jbi24061/`. Show the live dashboard running under subpath mode!

---

## 🎬 Episode 2: Secure Host Administration via Native Tailscale (Bypassing No-TUN)

### Episode Objective
Explain the unprivileged container restriction (`/dev/net/tun` missing) and demonstrate how to install Tailscale natively to get **secure remote SSH into `root@jbi24061`** and an outbound application proxy.

### Step-by-Step Script / Recording Workflow:
1. **Explain the Pitfall**:
   - Why running Tailscale inside Docker trapped our SSH in Alpine Linux (`Welcome to Alpine!`).
   - Why native `tailscale.service` failed with `router: enumerating tailscale0 addresses for cleanup failed`.
2. **Run the One-Click Host Setup**:
   - Run:
     ```bash
     chmod +x /opt/infra/scripts/setup-host-tailscale.sh
     ./opt/infra/scripts/setup-host-tailscale.sh
     ```
   - Explain what the script did:
     - Configured `/etc/systemd/system/tailscaled.service.d/override.conf` to clear `ExecStartPre` and enforce `--tun=userspace-networking`.
     - Enabled loopback SOCKS5/HTTP proxy on `127.0.0.1:1055`.
3. **Authenticate & Authorize**:
   - Run: `tailscale up --ssh --hostname=campus-lxc-node`.
   - Show the **Tailscale Admin Console**: Explain adding `root` to the `"ssh"` ACL rule.
4. **Demonstrate Remote Connection from Laptop**:
   - From your Windows PowerShell:
     ```powershell
     ssh root@campus-lxc-node
     ```
   - Show that it lands directly in `root@jbi24061 ~#` with zero open firewall ports!
5. **Demonstrate Private Application Proxy**:
   - Show routing traffic through `127.0.0.1:1055` to reach internal tailnet resources.

---

## 🎬 Episode 3: The Edge Ingress Gateway (Cloudflare Tunnel + NPM)

### Episode Objective
Eliminate the campus subpath constraint. Expose the server to the world using a custom domain (`vaultnode.site`) and wildcard subdomains (`*.vaultnode.site`) without opening firewall ports or buying public IPv4.

### Step-by-Step Script / Recording Workflow:
1. **Prepare Server Port 80**:
   - Stop and disable native Apache to free port 80 for Nginx Proxy Manager:
     ```bash
     systemctl stop apache2 && systemctl disable apache2
     ```
   - Create shared Docker bridge:
     ```bash
     docker network create infra_network
     ```
2. **Start Nginx Proxy Manager (NPM)**:
   - Run `cd /opt/infra/services/npm && docker compose up -d`.
   - Explain why NPM uses SQLite (< 70MB RAM footprint for 1 GB LXC).
3. **Configure Cloudflare Tunnel (Modern Routes UI)**:
   - Create tunnel `serverlab-jbi` in Cloudflare Zero Trust.
   - Put token into `/opt/infra/services/cloudflared/.env` and launch with `docker compose up -d`.
   - In Cloudflare Dashboard **Routes** tab, configure the exact 3 routes:
     - **Order 1:** `npm.vaultnode.site` $\rightarrow$ `http://npm:81`
     - **Order 2:** `vaultnode.site` $\rightarrow$ `http://npm:80`
     - **Order 3:** `*.vaultnode.site` $\rightarrow$ `http://npm:80`
   - **Crucial Teaching Moment**: Explain why Route 1 (`npm:81`) must be at the very top so the wildcard doesn't hijack admin requests!
4. **Access NPM Admin UI**:
   - Visit `https://npm.vaultnode.site`.
   - Log in with `admin@example.com` / `changeme`, update admin profile and password.

---

## 🎬 Episode 4: Track 2 — Containerized Production Laravel Deployment

### Episode Objective
Deploy the production containerized Laravel application with automatic Composer builds, database containerization, and zero-touch routing through NPM.

### Step-by-Step Script / Recording Workflow:
1. **Configure Application Stack**:
   - Navigate to `/opt/infra/examples/demo-laravel-app`.
   - Copy `.env.example` to `.env`:
     ```ini
     APP_DATA_DIR=/opt/app-data
     DEMO_APP_DOMAIN=pulse.vaultnode.site
     DB_DATABASE=db_serverlab
     DB_USERNAME=pulse_user
     DB_PASSWORD=strong_secret_password
     DB_ROOT_PASSWORD=strong_root_password
     ```
2. **Launch Application**:
   - Run `docker compose up -d --build`.
   - Highlight the **automated startup lifecycle**:
     - Multi-stage build pre-compiles Composer dependencies.
     - `entrypoint.sh` automatically creates `APP_KEY` if blank.
     - `Dockerfile.web` bundles web assets and connects cleanly to PHP-FPM.
     - MariaDB auto-seeds `schema.sql`.
3. **Route in NPM (Zero Cloudflare Changes)**:
   - Open `https://npm.vaultnode.site`.
   - Add Proxy Host:
     - Domain: `pulse.vaultnode.site`
     - Forward Hostname: `demo-pulse-web`
     - Forward Port: `80`
     - Enable: Block Common Exploits, Websockets Support.
   - Click Save.
4. **Grand Finale & Verification**:
   - Visit `https://pulse.vaultnode.site` on mobile phone and laptop.
   - Show the green live metrics, connected MariaDB, and zero-subpath clean URL!

---

## 🧹 Server Clean-Slate / Reset Instructions (Before You Record)

When you are ready to wipe all test containers and reset the server back to factory state before recording Episode 1, run the automated clean-slate script on the server:

```bash
cd /opt/infra
chmod +x scripts/reset-clean-slate.sh
./scripts/reset-clean-slate.sh
```

### What this script resets automatically:
1. **Docker**: Stops and removes `demo-pulse-*`, `infra-npm`, `infra-cloudflared`, and `infra_network`.
2. **App Data**: Wipes `/opt/app-data/{npm,cloudflared,demo-laravel-app}`.
3. **Tailscale**: Unauthenticates, purges `tailscale` packages, and removes systemd overrides.
4. **Apache & MariaDB**: Re-enables native host Apache2 (port 80) and MariaDB (port 3306).
5. **Webmin Webroot**: Recreates clean `/var/www/laravel/public/index.php` ready for Track 1 upload.
