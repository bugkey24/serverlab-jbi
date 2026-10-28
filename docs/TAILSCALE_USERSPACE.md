# Tailscale in Userspace Mode (No TUN Device)

## 1. Context & The "No TUN" Problem

In unprivileged Linux Containers (such as standard Proxmox LXC containers without host-level device passthrough), the Linux kernel virtual network device `/dev/net/tun` does **not** exist or is permission-restricted.

### What happens when running standard Tailscale or WireGuard:
```text
failed to create TUN device: open /dev/net/tun: no such file or directory
```
Because unprivileged containers cannot manipulate host kernel routing tables or mount arbitrary character devices without host admin intervention, standard Layer-3 VPN tunneling fails.

---

## 2. Solution: Userspace Networking Mode

Tailscale provides an internal networking stack implemented entirely in Go (`netstack`). In this mode:
1. Tailscale **does not** create a virtual network interface on the host kernel (`tailscale0`).
2. Tailscale listens as an internal **SOCKS5 and HTTP proxy** (by default on `127.0.0.1:1055`).
3. Tailscale can also run an internal SSH server (`tailscale ssh`) for secure, passwordless terminal access.

```mermaid
flowchart TD
    subgraph Host_Container [Unprivileged LXC Container]
        subgraph TS_Container [Docker: infra-tailscale]
            TS_Engine["Tailscaled (netstack engine)"]
            Proxy["SOCKS5 / HTTP Proxy (:1055)"]
            TSSSH["Tailscale SSH Daemon"]
            TS_Engine --> Proxy
            TS_Engine --> TSSSH
        end

        subgraph Local_Services [Local Tools & Services]
            Curl["curl / git"]
            LaravelApp["Laravel Backend Client"]
            Curl -->|ALL_PROXY=socks5://tailscale:1055| Proxy
            LaravelApp -->|HTTP/SOCKS Proxy| Proxy
        end
    end

    subgraph Tailscale_Coordination [Tailscale Control Plane / WireGuard]
        AdminDevice["Admin Laptop / Phone\n(Tailscale Client)"]
        AdminDevice -->|Direct WireGuard Peer-to-Peer| TS_Engine
        AdminDevice -->|tailscale ssh campus-lxc-node| TSSSH
    end
```

---

## 3. Deployment Configuration

### 3.1 Docker Compose Configuration (`services/tailscale/compose.yaml`)

```yaml
name: infra-tailscale

services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: infra-tailscale
    restart: unless-stopped
    environment:
      - TS_AUTHKEY=${TAILSCALE_AUTHKEY}
      - TS_HOSTNAME=${TAILSCALE_HOSTNAME:-campus-lxc-node}
      - TS_USERSPACE=true
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_EXTRA_ARGS=--tun=userspace-networking --socks5-server=0.0.0.0:1055 --outbound-http-proxy-listen=0.0.0.0:1055 --ssh
    volumes:
      - ${APP_DATA_DIR:-/opt/app-data}/infra/tailscale:/var/lib/tailscale
    ports:
      - "127.0.0.1:${TAILSCALE_PORT:-1055}:1055"
    networks:
      - infra_network

networks:
  infra_network:
    name: infra_network
    external: true
```

### 3.2 Key Arguments Explained:
- `TS_USERSPACE=true`: Instructs the startup script to use user-space networking.
- `--tun=userspace-networking`: Overrides interface creation.
- `--socks5-server=0.0.0.0:1055`: Exposes SOCKS5 proxy on port 1055 to other containers on `infra_network`.
- `--ssh`: Enables Tailscale SSH. You can connect from any authorized device on your tailnet with `tailscale ssh <hostname>` without exposing port 22.

---

## 4. Step-by-Step Setup Guide

### Step 1: Generate an Auth Key
1. Visit the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
2. Click **Generate auth key**.
3. Options:
   - **Reusable**: Yes (useful if rebuilding container).
   - **Ephemeral**: Optional (select if the container is temporary; uncheck for persistent nodes).
   - **Pre-authorized**: Recommended.
   - **Tags**: (e.g., `tag:server`).
4. Copy the generated key (`tskey-auth-...`).

### Step 2: Configure Environment
In `/opt/infra/services/tailscale/`:
```bash
cp .env.example .env
nano .env
```
Set values:
```bash
APP_DATA_DIR=/opt/app-data
TAILSCALE_AUTHKEY=tskey-auth-kXXXXX-YOUR_KEY_HERE
TAILSCALE_HOSTNAME=campus-lxc-node
TAILSCALE_PORT=1055
```

### Step 3: Launch Tailscale Service
```bash
cd /opt/infra/services/tailscale
docker compose up -d
docker compose logs -f
```
Verify output displays:
```text
boot: log in succeeded
...
Tailscale is up and running!
```

---

## 5. How to Use the Userspace Connection

### Scenario A: Remote Access via Tailscale SSH
On your developer laptop (with Tailscale installed and connected):
```bash
tailscale ssh campus-lxc-node
```
You now have secure, encrypted shell access without exposing public SSH ports.

### Scenario B: Using Local Applications Through the SOCKS5 Proxy
To route outgoing traffic from the server through your Tailscale network (e.g. to reach a private database on your tailnet):
```bash
export ALL_PROXY=socks5://127.0.0.1:1055
curl https://private-service.tailnet-name.ts.net
```

In PHP / Laravel:
```php
use Illuminate\Support\Facades\Http;

$response = Http::withOptions([
    'proxy' => 'socks5://127.0.0.1:1055',
])->get('https://internal-api.tailnet-name.ts.net/data');
```

---

## 6. Troubleshooting & Gotchas

#### 1. Container fails with `failed to create TUN device`
- **Cause**: `--tun=userspace-networking` was omitted or overridden.
- **Fix**: Verify `TS_USERSPACE=true` and `TS_EXTRA_ARGS=--tun=userspace-networking` are properly set in your environment.

#### 2. Ping fails to Tailscale IP
- **Expected Behavior**: In userspace networking mode, standard OS `ping` from the container host **will not work** because there is no Layer-3 kernel interface (`tailscale0`). Traffic must be proxied via SOCKS5/HTTP or accessed through `tailscale ssh`.
