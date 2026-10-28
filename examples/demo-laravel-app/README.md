# ServerLab Pulse: Demo Application

`ServerLab Pulse` is a lightweight, responsive server diagnostic and infrastructure validation web application built specifically to test and demonstrate two contrasting hosting architectures on restricted campus LXC / VPS servers:

1. **Track 1**: Manual Shared-Hosting deployment using **Webmin** (`:10000`) and **Adminer** (`:12322`) with **Zero-CLI / No-SSH access** behind a campus subpath prefix (`/jbi24061/`).
2. **Track 2**: Clean, containerized VPS deployment using **Docker Compose (`compose.yaml`)**, **Nginx Proxy Manager (NPM)**, **Cloudflare Tunnel**, and **Tailscale**, running at a clean root custom domain (`https://pulse.yourdomain.com/`).

---

## 📁 Project Structure

```text
examples/demo-laravel-app/
├── src/                                  # Pure application codebase
│   ├── database/
│   │   └── schema.sql                    # Initial schema & seed data (for Adminer / Docker init)
│   ├── public/
│   │   ├── index.php                     # Self-contained diagnostic app & Bootstrap 5 dashboard
│   │   └── .htaccess                     # Apache rewrite rules
│   ├── composer.json
│   └── .env.example                      # Configuration template
│
├── docker/                               # Track 2 Production Container Configurations
│   ├── Dockerfile                        # PHP 8.2-FPM Alpine container
│   └── nginx.conf                        # Nginx web server config
│
├── simulation/                           # Local Docker Simulation Suite
│   ├── compose.yaml                      # Simulates the entire campus setup locally
│   ├── campus-nginx.conf                 # Simulates upstream proxy (http://localhost:8080/jbi24061/)
│   ├── apache-vhost.conf                 # Simulates native TurnKey Apache VirtualHost
│   └── Dockerfile.lamp                   # Simulates TurnKey Apache + PHP image
│
├── compose.yaml                          # Production Track 2 Docker Compose manifest
├── .env.example                          # Track 2 Compose environment variables
├── serverlab-pulse.zip                   # Self-contained pre-packaged deployment archive for Webmin
├── dist/                                 # Uncompressed distribution output folder (Mode: dir)
│   └── serverlab-pulse/                  # Clean deployment tree ready for direct copy/sync
├── scripts/
│   ├── package-for-webmin.ps1            # Windows PowerShell packaging script (modes: zip, dir, all)
│   └── package-for-webmin.sh             # Linux/WSL/Docker bash packaging script (modes: zip, dir, all)
├── TRACK1_MANUAL_WEBMIN_GUIDE.md         # Full Webmin & Adminer GUI deployment runbook
└── TRACK2_DOCKER_VPS_GUIDE.md            # Full Docker VPS, NPM, and Tunnel deployment runbook
```

---

## 🧪 Local Simulation & Testing (Zero Host Tech-Stack Required)

You do **not** need to install PHP, Apache, or MariaDB on your computer. You can simulate and review both tracks locally using Docker!

### 1. Simulate Campus Track 1 Locally (Subpath + Apache + Adminer)

The local simulation spins up:
- An upstream Nginx proxy that forwards `http://localhost:8080/jbi24061/` to an internal Apache container.
- An Apache + PHP container serving `/var/www/laravel/public`.
- A MariaDB container pre-seeded with `schema.sql`.
- An Adminer container on `http://localhost:12322/`.

#### Run Simulation:
```bash
cd examples/demo-laravel-app/simulation
docker compose up -d
```

#### Test in Your Browser:
1. **Application UI**: Open `http://localhost:8080/jbi24061/` (or visit `http://localhost:8080/` which redirects there).
   - Observe the **Subpath Prefix** is detected as `/jbi24061`.
   - Observe **Runtime Mode** is `Native Apache (TurnKey LAMP Mode)`.
   - Try clicking **Register Node** to test creating a record through the subpath.
2. **Adminer Database UI**: Open `http://localhost:12322/`
   - System: `MySQL`, Server: `campus-mariadb`, Username: `root`, Password: `rootpassword`, Database: `db_serverlab`.
   - Test viewing and querying the database without ever touching a terminal.

---

### 2. Simulate Track 2 Locally (Docker VPS Mode)

To run the app as a pure Docker service:
```bash
cd examples/demo-laravel-app
cp .env.example .env
docker compose up -d
```
The app will connect to `infra_network` and can be proxied directly via your local Nginx Proxy Manager instance to test root domain routing.

---

## 📖 Detailed Guides

- [**Track 1: Manual Webmin & Adminer Guide**](TRACK1_MANUAL_WEBMIN_GUIDE.md)
- [**Track 2: Docker VPS & Cloudflare Tunnel Guide**](TRACK2_DOCKER_VPS_GUIDE.md)
