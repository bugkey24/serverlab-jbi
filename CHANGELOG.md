# Changelog

All notable changes and technical iterations for the campus infrastructure blueprint and demo application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **Host-Level Tailscale Deployment Script (`scripts/setup-host-tailscale.sh`)**:
  - Provides automated configuration of Tailscale in userspace networking mode directly on the TurnKey Debian 12 LXC host.
  - Configures `/etc/default/tailscaled` with `--tun=userspace-networking` and persistent SOCKS5/HTTP listeners on `127.0.0.1:1055`.
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
- **Tailscale Userspace Configuration Fix**:
  - Corrected parameter routing in [`services/tailscale/compose.yaml`](services/tailscale/compose.yaml) and [`docs/TAILSCALE_USERSPACE.md`](docs/TAILSCALE_USERSPACE.md).
  - Resolved `flag provided but not defined: -tun` container crash loop by decoupling daemon arguments from client arguments:
    - Dedicated native environment variables `TS_SOCKS5_SERVER=0.0.0.0:1055` and `TS_OUTBOUND_HTTP_PROXY_LISTEN=0.0.0.0:1055` now configure userspace proxies directly.
    - Set `TS_EXTRA_ARGS=--ssh` to pass CLI flags intended strictly for `tailscale up`.
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
