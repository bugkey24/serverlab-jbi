# Changelog

All notable changes and technical iterations for the campus infrastructure blueprint and demo application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **Tutorial Series Production Guide (`TUTORIAL_SERIES_PRODUCTION_GUIDE.md`)**:
  - Detailed 4-episode video tutorial blueprint covering:
    - Episode 1: Production Webmin Dashboard Deployment & Zero-CLI LAMP setup.
    - Episode 2: Native Tailscale in Unprivileged LXC with Userspace Netstack & Tailscale SSH.
    - Episode 3: Cloudflare Tunnel & Nginx Proxy Manager Ingress with Top-to-Bottom Route Order precedence.
    - Episode 4: Track 2 Containerized Laravel VPS Stack with Zero-Error Asset Serving & Self-Healing Entrypoint.
  - Complete with recording workflows, on-screen checklists, terminal commands, and common pitfalls to avoid.
- **Automated Server Clean-Slate Reset Utility (`scripts/reset-clean-slate.sh`)**:
  - One-click teardown script to restore TurnKey Linux 18 (Debian 12) LXC hosts back to fresh baseline state before recording.
  - Automatically shuts down all running Docker Compose stacks (demo app, NPM, Cloudflare Tunnel), prunes container networks/volumes, wipes `/opt/app-data/`, purges host Tailscale and its systemd drop-in override, and restores native host Apache2 and MariaDB services.
- **Dedicated Nginx Web Image for Track 2 (`examples/demo-laravel-app/docker/Dockerfile.web`)**:
  - Resolves Nginx 404 `realpath() "/var/www/html/public" failed` errors by bundling pre-built public static assets and FastCGI configuration directly into the container image.
- **Production Environment Hardening & Trusted Reverse Proxy Handling**:
  - Configured `$middleware->trustProxies(at: '*')` in [`src/bootstrap/app.php`](examples/demo-laravel-app/src/bootstrap/app.php) to ensure accurate HTTPS scheme evaluation, client IP resolution (preventing 172.18.0.x spoofing), and prevention of infinite redirect loops behind Cloudflare Tunnel and NPM.
  - Formatted and grouped production environment variables in [`examples/demo-laravel-app/.env.example`](examples/demo-laravel-app/.env.example) and [`compose.yaml`](examples/demo-laravel-app/compose.yaml), guaranteeing strict production isolation (`APP_ENV=production`, `APP_DEBUG=false`, `LOG_LEVEL=error`, `SESSION_DRIVER=cookie`).
- **Automated Docker Application Lifecycle & Self-Healing Entrypoint**:
  - Upgraded [`examples/demo-laravel-app/docker/Dockerfile`](examples/demo-laravel-app/docker/Dockerfile) to a multi-stage build that automatically bundles pre-compiled production Composer dependencies into the image.
  - Implemented [`docker/entrypoint.sh`](examples/demo-laravel-app/docker/entrypoint.sh) to automate runtime self-healing:
    - Auto-detects and provisions `vendor/` packages even when mounting code volumes without host dependencies.
    - Automatically generates cryptographically secure 256-bit `APP_KEY` if none is supplied in `.env`.
    - Automatically initializes directory structure and runtime permissions for `storage/` and `bootstrap/cache`.
  - Replaced raw directory mount with `volumes_from: app:ro` in [`compose.yaml`](examples/demo-laravel-app/compose.yaml) so Nginx and PHP-FPM share consistent, pre-built application assets.
- **Host-Level Tailscale Deployment Script (`scripts/setup-host-tailscale.sh`)**:
  - Provides automated configuration of Tailscale in userspace networking mode directly on the TurnKey Debian 12 LXC host.
  - Automatically installs systemd drop-in override (`/etc/systemd/system/tailscaled.service.d/override.conf`) clearing `ExecStartPre` to prevent `router: enumerating tailscale0 addresses for cleanup failed` crashes on unprivileged containers lacking `/dev/net/tun`.
  - Configures userspace netstack and persistent SOCKS5/HTTP listeners on `127.0.0.1:1055`.
  - Enables direct, passwordless remote SSH administration into the actual host (`root@jbi24061 ~#`) via Tailscale SSH rather than trapping sessions inside isolated container namespaces.
- **Official GitHub Repository Linkage**:
  - Connected project remote to [`https://github.com/bugkey24/serverlab-jbi.git`](https://github.com/bugkey24/serverlab-jbi.git).
  - Updated Quick Start instructions in `README.md` to reference the remote clone command.
- **Enhanced Multi-Format Track 1 Packaging Utilities**:
  - Added native Linux `tar.gz` (`serverlab-pulse.tar.gz`, ~12.3 MB) and uncompressed directory staging (`dist/serverlab-pulse`) to `package-for-webmin.ps1` and `package-for-webmin.sh`.
  - Re-architected `serverlab-pulse.zip` generation using BSDTar standard deflate archiving to eliminate Webmin Filemin incorrect password prompt errors.
  - Added automated CLI post-build reminders detailing manual production `APP_KEY` generation.
- **Manual Key Generation Workflow**:
  - Established a zero-placeholder policy for `APP_KEY` in production.
  - Documented cryptographically secure manual key generation workflows (via PowerShell RNG and OpenSSL) in `TRACK1_MANUAL_WEBMIN_GUIDE.md`.

### Changed
- **Modern Cloudflare Dashboard Routes UI Documentation**:
  - Updated [`docs/CLOUDFLARE_TUNNEL.md`](docs/CLOUDFLARE_TUNNEL.md) and [`docs/NGINX_PROXY_MANAGER.md`](docs/NGINX_PROXY_MANAGER.md) to detail Cloudflare's new Routes UI (`Published application`).
  - Added explicit instructions on route ordering (placing specific routes like `npm.yourdomain.com` -> `http://npm:81` at Order 1, above wildcard catch-all `*.yourdomain.com` -> `http://npm:80`) to prevent route hijacking.
- **Architectural Shift: Full Transition to Native Host Tailscale**:
  - Deprecated and removed the containerized Tailscale stack (`services/tailscale/`) to prevent SSH namespace entrapment (landing in Alpine Linux container shells instead of host TurnKey Debian).
  - Adopted native host `tailscaled` service managed by Debian systemd as the single source of truth for administrative SSH access and application proxying (`127.0.0.1:1055`).
  - Updated all infrastructure documentation, architecture topology diagrams, and automation scripts (`init-infra.sh`, `diagnose.sh`, `MIGRATION_LAMP_TO_DOCKER.md`, `TROUBLESHOOTING.md`, `TAILSCALE_USERSPACE.md`) to reflect the host-native design.
- **ServerLab Pulse Controller & View Hardening**:
  - Updated `ServerStatusController.php` to initialize `$nodes` as an `Illuminate\Support\Collection` via `collect()` rather than a raw array.
  - Hardened `dashboard.blade.php` with type-agnostic checks (`empty($nodes) || count($nodes) === 0`) to prevent `Call to a member function isEmpty() on array` exceptions before MariaDB tables are imported.
- **Mermaid Syntax Hardening across Documentation**:
  - Enclosed all subgraph headers in strict bracket-quote syntax (`subgraph ID ["Label"]`) to handle special characters, slashes, and curly braces safely.
  - Quoted all cylinder storage nodes (`[("npm/data<br>npm/letsencrypt")]`) and replaced unescaped newline `\n` characters with HTML `<br>` breaks.
  - Standardized edge connectors to pipe notation (`-->|Outbound QUIC Tunnel|`) to resolve GitHub Mermaid parser token errors (`got 'PS'`, `Expecting 'SQE'`).
  - Applied diagram fixes across `README.md`, `docs/ARCHITECTURE.md`, `docs/CLOUDFLARE_TUNNEL.md`, and `docs/TAILSCALE_USERSPACE.md`.
- **Git & Build Hygiene**:
  - Updated `.gitignore` to strictly ignore large generated distribution archives (`*.zip`, `*.tar.gz`, `dist/`).
  - Audited all directories to ensure zero live `.env`, certificate, or sensitive token files are tracked.

---

## Infrastructure Blueprint & Architecture Core (Initial Iterations)

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
