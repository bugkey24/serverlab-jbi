# Automation Scripts Reference & Documentation

This document provides a comprehensive inventory and functional breakdown of all automation, packaging, lifecycle, and reset scripts available in the **ServerLab JBI** campus hosting infrastructure.

---

## 📋 Complete Script Inventory

The project provides **9 specialized automation scripts** organized across three operational categories:

| Category | Script Path | Platform / Shell | Primary Role |
| :--- | :--- | :--- | :--- |
| **Tutorial Lifecycle & State Control** | [`scripts/prepare-tutorial1-state.sh`](prepare-tutorial1-state.sh) | Bash (Linux) | Rapid non-destructive reset before Tutorial 1 or between failed recording takes. |
| **Tutorial Lifecycle & State Control** | [`scripts/post-tutorial1-setup.sh`](post-tutorial1-setup.sh) | Bash (Linux) | Post-Tutorial 1 bridge: installs Docker, sets permissions, scaffolds `.env` and `infra_network`. |
| **Tutorial Lifecycle & State Control** | [`scripts/reset-clean-slate.sh`](reset-clean-slate.sh) | Bash (Linux) | Complete nuclear reset restoring TurnKey LXC to factory state (wiping Docker, Tailscale, data). |
| **Core Infrastructure & Networking** | [`scripts/setup-host-tailscale.sh`](setup-host-tailscale.sh) | Bash (Linux) | Installs native host Tailscale in userspace mode with systemd override for no-TUN LXC. |
| **Core Infrastructure & Networking** | [`scripts/init-infra.sh`](init-infra.sh) | Bash (Linux) | Initializes `/opt/app-data` directory structure, `.env` templates, and `infra_network`. |
| **Core Infrastructure & Networking** | [`scripts/diagnose.sh`](diagnose.sh) | Bash (Linux) | Health check verifying ports, systemd services, Docker containers, and Tailscale status. |
| **Track 1 Packaging & Artifacts** | [`examples/demo-laravel-app/scripts/package-for-webmin.ps1`](../examples/demo-laravel-app/scripts/package-for-webmin.ps1) | PowerShell (Windows) | Builds production `tar.gz`, `zip`, or directory artifacts with Composer dependencies. |
| **Track 1 Packaging & Artifacts** | [`examples/demo-laravel-app/scripts/package-for-webmin.sh`](../examples/demo-laravel-app/scripts/package-for-webmin.sh) | Bash (Linux/macOS) | Builds production `tar.gz`, `zip`, or directory artifacts with Composer dependencies. |
| **Track 2 Container Lifecycle** | [`examples/demo-laravel-app/docker/entrypoint.sh`](../examples/demo-laravel-app/docker/entrypoint.sh) | Shell (POSIX) | Container boot script: auto-generates `APP_KEY`, self-heals `vendor/`, and fixes permissions. |

---

## 🛠️ Detailed Documentation by Script

### 1. `scripts/prepare-tutorial1-state.sh`
- **Purpose**: Rapid preparation and reset tool designed specifically for video recording. If a take goes wrong during **Episode 1 (Webmin Track 1)**, this script instantly restores the initial clean state in seconds without uninstalling Docker or system packages.
- **Actions Performed**:
  1. Stops any running Docker containers that could conflict with host ports (80, 443, 3306).
  2. Restores and restarts native host **Apache2** on port 80.
  3. Restores and restarts native host **MariaDB** on port 3306.
  4. Automatically drops `db_serverlab` so Adminer database import steps can be re-recorded cleanly.
  5. Cleans `/var/www/laravel` and deploys a clean TurnKey LAMP welcome page at `/var/www/laravel/public/index.php`.
  6. Enforces `www-data:www-data` ownership with `755` permissions.
  7. Clears temporary upload archive leftovers (`.zip`, `.tar.gz`, `.sql`) from `/root` and `/tmp`.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/prepare-tutorial1-state.sh
  # Interactive mode:
  /opt/infra/scripts/prepare-tutorial1-state.sh

  # Rapid non-interactive mode (for quick retakes):
  /opt/infra/scripts/prepare-tutorial1-state.sh -y
  ```

---

### 2. `scripts/post-tutorial1-setup.sh`
- **Purpose**: Transition script executed directly after completing Tutorial 1. It bridges the gap between shared-hosting Apache mode and the upcoming Docker, Tailscale, and Cloudflare episodes.
- **Actions Performed**:
  1. Verifies `/var/www/laravel` health and locks `www-data:775` permissions on `storage/` and `bootstrap/cache`.
  2. Checks for `curl`, `git`, `iptables`, and `ca-certificates`.
  3. Automatically installs Docker Engine and the Docker Compose plugin if missing.
  4. Creates standard persistent volume directories under `/opt/app-data/{service}/{component}`.
  5. Creates the shared Docker bridge network `infra_network`.
  6. Copies `.env.example` templates to `.env` for Cloudflare Tunnel, NPM, and Demo App.
  7. Offers an interactive prompt to stop/disable native Apache2 when ready to release port 80 for Nginx Proxy Manager.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/post-tutorial1-setup.sh
  /opt/infra/scripts/post-tutorial1-setup.sh
  ```

---

### 3. `scripts/reset-clean-slate.sh`
- **Purpose**: Full nuclear teardown and reset tool. Restores a heavily tested LXC host back to its original factory state.
- **Actions Performed**:
  1. Stops and removes all Docker Compose stacks (`demo-pulse-*`, `npm`, `cloudflared`) and orphan containers.
  2. Deletes the `infra_network` Docker bridge.
  3. Wipes all persistent data under `/opt/app-data/`.
  4. Logs out, disables, and completely uninstalls native host Tailscale and its systemd drop-in override.
  5. Unmasks, enables, and restarts host Apache2 and MariaDB.
  6. Restores a clean placeholder in `/var/www/laravel/public/index.php`.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/reset-clean-slate.sh
  /opt/infra/scripts/reset-clean-slate.sh
  ```

---

### 4. `scripts/setup-host-tailscale.sh`
- **Purpose**: Solves the unprivileged Proxmox LXC problem where `/dev/net/tun` is missing, allowing Tailscale to run natively on the Debian host without crashing.
- **Actions Performed**:
  1. Installs official Tailscale Debian package and GPG repository keys.
  2. Creates a systemd service drop-in override (`/etc/systemd/system/tailscaled.service.d/override.conf`) clearing `ExecStartPre` to prevent `enumerating tailscale0 addresses failed` crashes.
  3. Sets flags `--tun=userspace-networking` and `--socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055`.
  4. Reloads systemd daemon and restarts `tailscaled`.
  5. Enables Tailscale SSH so remote developers land directly in `root@jbi24061 ~#`.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/setup-host-tailscale.sh
  /opt/infra/scripts/setup-host-tailscale.sh
  tailscale up --ssh --hostname=campus-lxc-node
  ```

---

### 5. `scripts/init-infra.sh`
- **Purpose**: Standard initialization script for production deployments using Docker.
- **Actions Performed**:
  1. Validates root execution.
  2. Builds `/opt/app-data/cloudflared/config`, `/opt/app-data/npm/data`, and `/opt/app-data/npm/letsencrypt`.
  3. Prepares default `.env` files for services.
  4. Detects active Apache and provides an option to disable it.
  5. Provisions `infra_network`.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/init-infra.sh
  /opt/infra/scripts/init-infra.sh
  ```

---

### 6. `scripts/diagnose.sh`
- **Purpose**: Quick system diagnostics and troubleshooting utility to inspect server health across all layers.
- **Actions Performed**:
  1. Checks listening ports (80, 81, 443, 3306, 10000, 12322, 1055).
  2. Checks systemd status for Apache2, MariaDB, and Tailscale.
  3. Inspects running Docker containers and health status.
  4. Tests loopback HTTP responses.
- **Usage**:
  ```bash
  chmod +x /opt/infra/scripts/diagnose.sh
  /opt/infra/scripts/diagnose.sh
  ```

---

### 7. `package-for-webmin.ps1` & `package-for-webmin.sh`
- **Location**: `examples/demo-laravel-app/scripts/`
- **Purpose**: Builds self-contained, pre-compiled application packages on your local workstation for uploading to Webmin Filemin without requiring Composer on the server.
- **Supported Targets**:
  - `targz`: Generates `serverlab-pulse.tar.gz` (~12 MB, preserves UNIX permissions, recommended for TurnKey Linux).
  - `zip`: Generates `serverlab-pulse.zip` (~17 MB, standard deflate archive).
  - `dir`: Generates uncompressed `dist/serverlab-pulse` directory.
  - `all`: Builds all three formats simultaneously.
- **Usage**:
  - **PowerShell (Windows)**:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\examples\demo-laravel-app\scripts\package-for-webmin.ps1 targz
    ```
  - **Bash (Linux / macOS)**:
    ```bash
    bash examples/demo-laravel-app/scripts/package-for-webmin.sh targz
    ```

---

### 8. `entrypoint.sh` (Track 2 Container Runtime)
- **Location**: `examples/demo-laravel-app/docker/entrypoint.sh`
- **Purpose**: Container startup script for PHP-FPM (`demo-pulse-app`).
- **Actions Performed**:
  1. Checks if `.env` exists; copies from `.env.example` if missing.
  2. Checks `APP_KEY`; auto-generates a 256-bit cryptographic key if empty.
  3. Detects if `vendor/` exists; self-heals by running `composer install --no-dev` if missing.
  4. Ensures `storage/` and `bootstrap/cache` directories exist with proper write permissions.
  5. Clears Laravel configuration cache (`php artisan config:clear`).
  6. Executes `php-fpm` as PID 1.
