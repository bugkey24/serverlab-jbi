# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-10-28

### Added
- **ServerLab Pulse (Demonstration & Validation Project)**:
  - Clean PHP 8.2 & Bootstrap 5 web application located at `examples/demo-laravel-app/`.
  - Self-contained diagnostic dashboard showing runtime mode (TurnKey LAMP vs Docker VPS), memory usage, database latency, and ingress gateway inspection (`X-Forwarded-For` / `CF-Connecting-IP`).
  - Interactive server node registry for testing MariaDB connectivity and write operations.
  - Subpath auto-detection engine allowing the application to run seamlessly under both campus subpaths (`/jbi24061/`) and root custom domains (`pulse.yourdomain.com`).
- **Dual Deployment Tracks & Documentation**:
  - `TRACK1_MANUAL_WEBMIN_GUIDE.md`: Step-by-step tutorial for zero-CLI shared-hosting deployment using Webmin File Manager (`:10000`) and Adminer (`:12322`).
  - `TRACK2_DOCKER_VPS_GUIDE.md`: Production runbook for containerized VPS deployment integrating with NPM, Cloudflare Tunnel, and Tailscale.
- **Local Simulation Suite (`examples/demo-laravel-app/simulation/`)**:
  - Fully containerized local test harness simulating the campus host Nginx reverse proxy (`http://localhost:8080/jbi24061/`), Apache virtual host, MariaDB, and Adminer without requiring any local PHP or MySQL installation.
- **Granular Persistent Volume Standard**:
  - Standardized all application and infrastructure volume mounts to `/opt/app-data/{app-or-service}/{component-or-service}`.

---

## [1.2.0] - 2026-10-28
### Added
- **ServerLab Pulse (Authentic Laravel 13 & Bootstrap 5 Demo)**:
  - Standard Laravel 13.39.0 application engine under `examples/demo-laravel-app/src` running PHP 8.3.
  - Zero-CLI Track 1 packaging pipeline generating self-contained `serverlab-pulse.zip` with full vendor bundles and pre-seeded SQL schema.
  - Complete local Docker simulation environment under `examples/demo-laravel-app/simulation` testing campus Nginx subpath reverse proxy (`/jbi24061/`) and Adminer without installing local PHP/MariaDB.
  - Production Track 2 Docker Compose specification (`examples/demo-laravel-app/compose.yaml`) with Alpine-based PHP 8.3-FPM, Nginx, and MariaDB 10.11.
  - Detailed guides: [`TRACK1_MANUAL_WEBMIN_GUIDE.md`](examples/demo-laravel-app/TRACK1_MANUAL_WEBMIN_GUIDE.md) and [`TRACK2_DOCKER_VPS_GUIDE.md`](examples/demo-laravel-app/TRACK2_DOCKER_VPS_GUIDE.md).
- **Security & Secret Sanitization**:
  - Full audit confirming zero active tokens, credentials, or private keys in the tree.
  - All configuration templates sanitized to `.env.example`.

## [1.1.0] - 2026-10-27

### Changed
- **Modern Compose Specification Adoption**:
  - Migrated legacy `docker-compose.yml` filenames to the modern Docker Compose standard `compose.yaml` across all service modules.
- **Decoupled Autonomous Service Architecture**:
  - Removed monolithic root compose file.
  - Each infrastructure component (`cloudflared`, `npm`, `tailscale`) now lives in its own dedicated directory under `services/`.
  - Moved `.env` configuration to individual service directories (`services/<svc>/.env.example`) so each service can be managed, started, or stopped completely independently.
- **Updated Initialization & Diagnostics**:
  - Updated `scripts/init-infra.sh` to initialize per-service `.env` templates and prepare standalone directories.

---

## [1.0.0] - 2026-10-27

### Added
- **Clean Architecture Directory Standard**:
  - `/opt/infra`: Declarative core infrastructure definitions.
  - `/opt/apps`: Multi-application project directories.
  - `/opt/app-data`: Centralized persistent volume storage for zero-data-loss upgrades and lean backups.
- **Tailscale in Userspace Networking Mode**:
  - Netstack implementation bypassing the unprivileged LXC `/dev/net/tun` restriction.
  - SOCKS5 and HTTP proxy listener on port `1055`.
  - Integrated Tailscale SSH daemon for passwordless administration.
- **Cloudflare Zero Trust Tunnel Connector**:
  - Automated outbound-only connector (`cloudflared`) bypassing campus firewall rules, lack of public IPv4, and host reverse proxy path restrictions.
  - Wildcard domain dispatch pattern forwarding to local reverse proxy.
- **Nginx Proxy Manager (NPM)**:
  - Low-resource configuration with embedded SQLite (< 70MB RAM consumption).
  - Web UI for point-and-click routing, custom subdomains, and SSL management.
  - Loopback-bound administrative UI (`127.0.0.1:81`) for zero-trust security.
- **Enterprise-Grade Documentation**:
  - High-level architecture overview with Mermaid topology diagrams ([ARCHITECTURE.md](docs/ARCHITECTURE.md)).
  - Tailscale Userspace guide and workarounds ([TAILSCALE_USERSPACE.md](docs/TAILSCALE_USERSPACE.md)).
  - Cloudflare Tunnel edge routing guide ([CLOUDFLARE_TUNNEL.md](docs/CLOUDFLARE_TUNNEL.md)).
  - Nginx Proxy Manager setup & SSL routing ([NGINX_PROXY_MANAGER.md](docs/NGINX_PROXY_MANAGER.md)).
  - TurnKey LAMP to Docker migration runbook ([MIGRATION_LAMP_TO_DOCKER.md](docs/MIGRATION_LAMP_TO_DOCKER.md)).
  - Comprehensive troubleshooting runbook ([TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)).
