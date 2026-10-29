# Track 2 Guide: Full Docker VPS Deployment (NPM, Cloudflare & Tailscale)

## 1. Overview & Objective

This track demonstrates the **clean, automated, containerized VPS workflow**.
By transitioning from the native TurnKey LAMP stack to Docker:
1. We **disable native Apache, PHP, and MariaDB** on the host.
2. The application is deployed in `/opt/apps/demo-laravel-app` with isolated database and storage mounts in `/opt/app-data/demo-laravel-app/{database,storage}`.
3. The application connects to `infra_network`.
4. **Nginx Proxy Manager (NPM)** handles all routing and SSL certificates.
5. **Cloudflare Tunnel** exposes the application globally on a custom domain (e.g. `https://pulse.yourdomain.com/`) with zero subpath constraints.

---

## 2. Architecture Comparison

```text
Track 1 (Campus Subpath):
Client -> Campus Nginx (tajbi.poliwangi.ac.id/jbi24061/) -> Native Apache (:80) -> Native MariaDB

Track 2 (Docker VPS):
Client -> Cloudflare Edge (*.yourdomain.com) -> cloudflared -> NPM (npm:80) -> demo-pulse-web -> demo-pulse-app
```

---

## 3. Step-by-Step Transition & Deployment

### Step 1: Disable Native TurnKey Host Services
Free port 80, 443, and MariaDB memory by stopping and disabling native services:

```bash
# Stop and disable native Apache
sudo systemctl stop apache2
sudo systemctl disable apache2

# Stop and disable native MariaDB
sudo systemctl stop mariadb
sudo systemctl disable mariadb

# Verify ports 80, 443, and 3306 are no longer bound by host services
sudo ss -tulpn | grep -E ':(80|443|3306)'
```

### Step 2: Establish the Clean Directory Structure
Ensure volume mounts exist under the clean standard:

```bash
sudo mkdir -p /opt/apps/demo-laravel-app
sudo mkdir -p /opt/app-data/demo-laravel-app/database
sudo mkdir -p /opt/app-data/demo-laravel-app/storage
```

### Step 3: Place Application Code & Configure Environment
Place the application files in `/opt/apps/demo-laravel-app`:

```bash
cd /opt/apps/demo-laravel-app
cp .env.example .env
nano .env
```

Configure:
```ini
APP_DATA_DIR=/opt/app-data
DEMO_APP_DOMAIN=pulse.yourdomain.com

# Optional: Custom APP_KEY (if empty, entrypoint.sh auto-generates a secure key)
APP_KEY=

DB_DATABASE=db_serverlab
DB_USERNAME=pulse_user
DB_PASSWORD=pulse_secret_pass
DB_ROOT_PASSWORD=root_secret_pass
```

### Step 4: Launch Application Stack
Start the containerized application:

```bash
docker compose up -d --build
docker compose ps
```

> [!TIP]
> **Fully Automated Startup Workflow**:
> The multi-stage Docker build automatically installs and optimizes all Composer dependencies into the image. On container startup, the automated entrypoint script (`entrypoint.sh`):
> 1. Verifies that `vendor/autoload.php` is in place.
> 2. Auto-generates a 256-bit cryptographic `APP_KEY` if none was set in `.env`.
> 3. Configures directory permissions (`775` on `storage/` and `bootstrap/cache`).
> 4. Auto-seeds the database schema via `schema.sql` on MariaDB's initial launch.
> No manual `composer install` or key generation commands are needed!

### Step 5: Route Through Nginx Proxy Manager (NPM)
1. Open the NPM Admin Dashboard (`http://localhost:81` via Tailscale or SSH tunnel `ssh -L 8181:localhost:81 user@host`).
2. Navigate to **Hosts** -> **Proxy Hosts** -> **Add Proxy Host**:
   - **Domain Names**: `pulse.yourdomain.com`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `demo-pulse-web`
   - **Forward Port**: `80`
   - Enable: **Block Common Exploits** and **Websockets Support**.
3. Under the **SSL** tab:
   - Request a Let's Encrypt certificate (or trust Cloudflare Edge termination).
4. Click **Save**.

---

## 4. Verification

Visit your custom domain in your browser:
```text
https://pulse.yourdomain.com/
```

### Expected Result:
- The **ServerLab Pulse** interface loads instantly at the root domain without any `/jbi24061/` subpath.
- The **Runtime Mode** badge displays: `Docker Container (VPS Mode)`.
- The **Ingress Gateway** shows: `Cloudflare Zero Trust Edge (Tunnel)` or `Upstream Reverse Proxy (NPM)`.
- The **Database Status** card shows: `Connected` to the isolated MariaDB container.
- Full CRUD operations work cleanly, with data preserved under `/opt/app-data/demo-laravel-app/`.
