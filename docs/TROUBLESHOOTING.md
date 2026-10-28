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

### 2.1 Tailscale Userspace

#### Symptom: `failed to create TUN device: open /dev/net/tun: no such file or directory`
- **Cause**: The container attempted to initialize kernel TUN device mode inside an unprivileged container.
- **Resolution**:
  1. Inspect `/opt/infra/services/tailscale/compose.yaml`.
  2. Ensure `TS_USERSPACE=true` is set.
  3. Ensure `TS_EXTRA_ARGS` includes `--tun=userspace-networking`.
  4. Ensure no capabilities like `NET_ADMIN` or device mounts `/dev/net/tun` are specified if unprivileged.

#### Symptom: Cannot connect via `tailscale ssh <node>`
- **Cause**: Key expiry or missing `--ssh` flag on tailscaled.
- **Resolution**:
  1. Verify Tailscale container logs: `docker logs infra-tailscale`.
  2. Check if the node is online in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines).
  3. Re-authenticate if the key expired.

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
