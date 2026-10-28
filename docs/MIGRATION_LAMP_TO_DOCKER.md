# Migration Guide: TurnKey Native LAMP to Clean Docker Infrastructure

## 1. Migration Strategy Overview

This guide details how to transition an existing TurnKey LAMP deployment (running natively on Debian 12 / Proxmox LXC) to the clean containerized architecture (`/opt/infra`, `/opt/apps`, `/opt/app-data`).

The transition is designed for:
- **Zero data loss**: Safe database dumps and document root archival.
- **Minimal downtime**: Staged validation before killing native host services.
- **Clean rollback path**: Native services can be restarted immediately if any step fails.

---

## 2. Pre-Migration Audit

Run the following commands inside the container to inspect existing services and paths:

```bash
# 1. Check disk usage and free memory
df -h
free -m

# 2. Check listening ports
ss -tulpn

# 3. Identify running native services
systemctl status apache2 mariadb --no-pager
```

Document the current paths:
- Laravel project root: typically `/var/www/laravel`
- Apache VirtualHost config: `/etc/apache2/sites-available/`
- MariaDB database name & credentials: from `.env` in the Laravel project

---

## 3. Step-by-Step Migration Workflow

### Step 1: Backup Native Databases
Before changing any services, perform a full MySQL dump:

```bash
mkdir -p /root/migration_backups

# Export all databases (or specific application database)
mysqldump -u root -p --all-databases > /root/migration_backups/full_db_backup_$(date +%F).sql

# Verify backup file size
ls -lh /root/migration_backups/
```

### Step 2: Backup Native Application Files
Archive the current Laravel application source and uploaded media:

```bash
tar -czvf /root/migration_backups/laravel_code_$(date +%F).tar.gz /var/www/laravel
```

### Step 3: Establish the Clean Directory Structure
Run the infrastructure initialization script:

```bash
sudo /opt/infra/scripts/init-infra.sh
```

### Step 4: Stop and Disable Conflicting Native Services
To liberate Port 80 and 443 for Docker / NPM, disable Apache:

```bash
# Stop Apache
sudo systemctl stop apache2

# Prevent Apache from automatically starting on boot
sudo systemctl disable apache2

# Verify Port 80 is now free
sudo ss -tulpn | grep ':80 '
```

### Step 5: Configure and Launch Core Infrastructure Services
Launch each infrastructure component independently from its directory:

```bash
# 1. Nginx Proxy Manager
cd /opt/infra/services/npm
cp .env.example .env
nano .env
docker compose up -d

# 2. Cloudflare Tunnel
cd /opt/infra/services/cloudflared
cp .env.example .env
nano .env
docker compose up -d

# 3. Native Host Tailscale (Userspace Netstack + SSH)
chmod +x /opt/infra/scripts/setup-host-tailscale.sh
/opt/infra/scripts/setup-host-tailscale.sh
tailscale up --ssh --hostname=campus-lxc-node
```

### Step 6: Deploy Containerized Application
Migrate your Laravel application to `/opt/apps/laravel`:

1. Copy application files to `/opt/apps/laravel`.
2. Move persistent storage (`storage/`, SQLite DB, or uploaded files) into `/opt/app-data/apps/laravel/storage`.
3. Use a lightweight PHP-FPM + Nginx or Octane/FrankenPHP Docker container.
4. Join the application container to `infra_network`.
5. Open Nginx Proxy Manager (`localhost:81`) and add a Proxy Host targeting the new container.

---

## 4. Rollback Procedure (Emergency Recovery)

If unexpected issues occur and you need to restore the native LAMP stack immediately:

```bash
# 1. Stop all Docker infrastructure services
cd /opt/infra/services/cloudflared && docker compose down
cd /opt/infra/services/npm && docker compose down

# 2. Restart native Apache
sudo systemctl start apache2

# 3. Ensure native MariaDB is running
sudo systemctl start mariadb

# 4. Verify host services are listening
sudo ss -tulpn | grep -E ':(80|3306)'
```
Your original native setup will immediately resume serving traffic on the campus path.
