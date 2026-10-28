# Changelog

All notable changes and technical iterations for the campus infrastructure blueprint and demo application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
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
- **ServerLab Pulse Controller & View Hardening**:
  - Updated `ServerStatusController.php` to initialize `$nodes` as an `Illuminate\Support\Collection` via `collect()` rather than a raw array.
  - Hardened `dashboard.blade.php` with type-agnostic checks (`empty($nodes) || count($nodes) === 0`) to prevent `Call to a member function isEmpty() on array` exceptions before MariaDB tables are imported.
- **Mermaid Syntax Compatibility**:
  - Quoted subgraph and node labels containing parentheses across `README.md` and `docs/ARCHITECTURE.md` to fix parser errors on GitHub.
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
