# Unified Troubleshooting & Diagnostics Runbook

This guide covers common errors, diagnostic commands, and recovery procedures across the entire infrastructure stack.

---

## 1. Fast Health Check Matrix

Run these diagnostic commands to get a quick snapshot of system health:

```bash
# 1. System Resources & Memory Pressure
free -h
top -b -n 1 | head -n 20

# 2. Container Status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

# 3. Network Ports
ss -tulpn

# 4. Docker Network Inspection
docker network inspect infra_network
```

---

## 2. Service-Specific Troubleshooting

### 2.1 Tailscale Userspace (Host-Native Implementation)

#### Symptom: `router: enumerating tailscale0 addresses for cleanup failed`
- **Cause**: Stock `tailscaled.service` on Debian calls `ExecStartPre=/usr/sbin/tailscaled --cleanup`, which looks for the kernel interface `tailscale0`. In unprivileged LXC without `/dev/net/tun`, this causes `exit-code` failure during systemd startup.
- **Resolution**:
  1. Add systemd drop-in override:
     ```bash
     mkdir -p /etc/systemd/system/tailscaled.service.d
     cat << 'EOF' > /etc/systemd/system/tailscaled.service.d/override.conf
     [Service]
     ExecStartPre=
     ExecStart=
     ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --tun=userspace-networking --socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055
     EOF
     systemctl daemon-reload
     systemctl restart tailscaled
     ```

#### Symptom: SSH lands in Alpine Linux (`Welcome to Alpine!`) instead of TurnKey Host
- **Cause**: Tailscale was running in a Docker container with `--ssh`. Containerized Tailscale traps SSH inside its own isolated container filesystem.
- **Resolution**:
  1. Transition to native host setup: run `/opt/infra/scripts/setup-host-tailscale.sh`.
  2. Authenticate directly on the host: `tailscale up --ssh --hostname=campus-lxc-node`.

#### Symptom: `tailscale: tailnet policy does not permit you to SSH as user "root"` (or `"asus"`)
- **Cause**: Tailscale ACLs enforce zero-trust policies and block unlisted users.
- **Resolution**:
  1. Open [Tailscale Admin Console: Access Controls](https://login.tailscale.com/admin/acls).
  2. Add `root` (and any local client usernames) to the `"ssh"` block.

#### Symptom: `failed to create TUN device: open /dev/net/tun: no such file or directory`
- **Cause**: The daemon attempted to initialize kernel TUN device mode inside an unprivileged container.
- **Resolution**:
  1. Inspect `/etc/default/tailscaled` on the host.
  2. Ensure `FLAGS="--tun=userspace-networking --socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055"` is present.
  3. Restart the service: `systemctl restart tailscaled`.

#### Symptom: Cannot connect via `tailscale ssh <node>`
- **Cause**: Key expiry or missing `--ssh` flag on `tailscale up`.
- **Resolution**:
  1. Check host service status: `systemctl status tailscaled`.
  2. Check if the node is online in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines).
  3. Re-authenticate: `tailscale up --ssh --hostname=campus-lxc-node`.

---

### 2.2 Cloudflare Tunnel

#### Symptom: `Error: failed to sufficiently increase receive buffer size`
- **Cause**: Linux kernel socket buffer recommendation from quic-go. This is a non-fatal warning, but performance can be optimized.
- **Fix** (if permitted inside container):
  ```bash
  sysctl -w net.core.rmem_max=2500000
  ```

#### Symptom: HTTP 502 Bad Gateway on Custom Domain
- **Flow to check**:
  `Client -> Cloudflare Edge -> cloudflared -> NPM (npm:80) -> App Container`
- **Steps**:
  1. Check if `cloudflared` is connected:
     ```bash
     docker logs infra-cloudflared --tail 50
     ```
  2. Test internal connection from `cloudflared` to `npm`:
     ```bash
     docker exec -it infra-cloudflared curl -I http://npm:80
     ```
  3. If connection refused: check if `infra-npm` is running and on `infra_network`.

---

### 2.3 Nginx Proxy Manager (NPM)

#### Symptom: Container crashes or reboots continuously (`EADDRINUSE :80`)
- **Cause**: Port 80 is occupied by host Apache or another service.
- **Fix**:
  ```bash
  sudo systemctl stop apache2
  sudo systemctl disable apache2
  docker restart infra-npm
  ```

#### Symptom: High Memory Usage / OOM Kill
- **Context**: 1 GB RAM LXC ceiling.
- **Resolution**:
  1. Ensure NPM is running on default embedded SQLite rather than external MySQL/MariaDB.
  2. Check memory consumption: `docker stats --no-stream`.
  3. Add memory resource limits to `services/npm/compose.yaml`:
     ```yaml
     deploy:
       resources:
         limits:
           memory: 150M
     ```

---

## 3. General Docker & Network Commands

| Objective | Command |
| :--- | :--- |
| View live logs of a specific service | `cd /opt/infra/services/<svc> && docker compose logs -f` |
| Restart a specific service | `cd /opt/infra/services/<svc> && docker compose restart` |
| Stop a service | `cd /opt/infra/services/<svc> && docker compose down` |
| Test DNS resolution inside Docker network | `docker run --rm --network infra_network busybox nslookup npm` |
| Prune unused images and containers | `docker system prune -f` |
