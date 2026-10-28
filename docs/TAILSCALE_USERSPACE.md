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
    subgraph Host_Container ["Unprivileged LXC Container"]
        subgraph TS_Container ["Docker: infra-tailscale"]
            TS_Engine["Tailscaled (netstack engine)"]
            Proxy["SOCKS5 / HTTP Proxy (:1055)"]
            TSSSH["Tailscale SSH Daemon"]
            TS_Engine --> Proxy
            TS_Engine --> TSSSH
        end

        subgraph Local_Services ["Local Tools & Services"]
            Curl["curl / git"]
            LaravelApp["Laravel Backend Client"]
            Curl -->|ALL_PROXY=socks5://tailscale:1055| Proxy
            LaravelApp -->|HTTP/SOCKS Proxy| Proxy
        end
    end

    subgraph Tailscale_Coordination ["Tailscale Control Plane / WireGuard"]
        AdminDevice["Admin Laptop / Phone<br>(Tailscale Client)"]
        AdminDevice -->|Direct WireGuard Peer-to-Peer| TS_Engine
        AdminDevice -->|tailscale ssh campus-lxc-node| TSSSH
    end
```

---

## 2. Architecture Comparison: Host-Level vs. Containerized

Depending on your access requirements:

| Feature | Pattern A: Host-Level Tailscale (Recommended) | Pattern B: Containerized Tailscale |
| :--- | :--- | :--- |
| **Where Tailscale Runs** | Direct systemd service on TurnKey Debian host | Isolated Docker container (`infra-tailscale`) |
| **Tailscale SSH Target** | **Host OS** (`root@jbi24061 ~#`) | **Alpine Container** (`root@4be38c45cb23:~#`) |
| **Access to Host Services** | Full native control (`systemctl`, `docker`, `/opt`) | Isolated inside container namespace |
| **Outbound App Proxy** | `127.0.0.1:1055` directly on host | Forwarded from container via Docker port |
| **Setup Script** | [`scripts/setup-host-tailscale.sh`](../scripts/setup-host-tailscale.sh) | `services/tailscale/compose.yaml` |

> [!IMPORTANT]
> If your primary goal is remote terminal administration into the TurnKey Linux LXC container (`root@jbi24061`), use **Pattern A (Host-Level)**. Running Tailscale inside a Docker container intercepts Tailscale SSH within that container's own Alpine filesystem.

---

## 3. Pattern A: Host-Level Deployment (Direct LXC SSH Access)

### Automated Setup
On your TurnKey Debian host (`root@jbi24061`):
```bash
sudo chmod +x /opt/infra/scripts/setup-host-tailscale.sh
sudo /opt/infra/scripts/setup-host-tailscale.sh
```

### Manual Setup Steps
1. **Configure systemd for Userspace Netstack**:
   Create or edit `/etc/default/tailscaled`:
   ```bash
   FLAGS="--tun=userspace-networking --socks5-server=127.0.0.1:1055 --outbound-http-proxy-listen=127.0.0.1:1055"
   ```
2. **Reload and Restart**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now tailscaled
   ```
3. **Authenticate with Tailscale SSH**:
   ```bash
   sudo tailscale up --ssh --hostname=campus-lxc-node
   ```

---

## 4. Pattern B: Docker Containerized Deployment

### 4.1 Docker Compose Configuration (`services/tailscale/compose.yaml`)

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
      - TS_SOCKS5_SERVER=0.0.0.0:1055
      - TS_OUTBOUND_HTTP_PROXY_LISTEN=0.0.0.0:1055
      - TS_EXTRA_ARGS=--ssh
    volumes:
      - ${APP_DATA_DIR:-/opt/app-data}/tailscale/state:/var/lib/tailscale
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
- `TS_USERSPACE=true`: Instructs the container entrypoint to start `tailscaled` with `--tun=userspace-networking` (bypassing `/dev/net/tun`).
- `TS_SOCKS5_SERVER=0.0.0.0:1055`: Starts a local SOCKS5 proxy on port 1055, accessible to other containers on `infra_network`.
- `TS_OUTBOUND_HTTP_PROXY_LISTEN=0.0.0.0:1055`: Starts a local HTTP/HTTPS proxy on the same port.
- `TS_EXTRA_ARGS=--ssh`: Flags forwarded specifically to `tailscale up`. Enables Tailscale SSH so you can run `tailscale ssh <hostname>` from any peer node without opening port 22. *(Note: `--tun` is a daemon argument, never pass `--tun` into `TS_EXTRA_ARGS` as `tailscale up` does not accept it).*

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

#### 1. SSH lands in Alpine Linux (`Welcome to Alpine!`) instead of TurnKey Host
- **Cause**: Tailscale was started with `--ssh` inside the Docker container (`infra-tailscale`). The official Tailscale Docker image runs Alpine Linux.
- **Fix**: To SSH into the real Debian host (`root@jbi24061`), stop the Docker Tailscale container and run Tailscale directly on the host using `scripts/setup-host-tailscale.sh`.

#### 2. `tailscale: tailnet policy does not permit you to SSH as user "root"` (or `"asus"`)
- **Cause**: Tailscale ACLs enforce strict SSH permission. By default, high-privilege accounts like `root` are blocked unless explicitly permitted.
- **Fix**: Open the [Tailscale Admin Console: Access Controls](https://login.tailscale.com/admin/acls) and add `root` to the `ssh` block:
  ```json
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self", "tag:server"],
      "users": ["root", "autogroup:nonroot"]
    }
  ]
  ```

#### 3. Container fails with `flag provided but not defined: -tun`
- **Cause**: `--tun=userspace-networking` was incorrectly placed in `TS_EXTRA_ARGS`. In Tailscale's Docker container, `TS_EXTRA_ARGS` is passed to the CLI command `tailscale up`, whereas `--tun` is a flag strictly for the `tailscaled` daemon.
- **Fix**: Remove `--tun=...` from `TS_EXTRA_ARGS`. Setting `TS_USERSPACE=true` automatically launches `tailscaled` with `--tun=userspace-networking`.

#### 2. Container fails with `failed to create TUN device`
- **Cause**: `TS_USERSPACE=true` was omitted or set to `false` without `/dev/net/tun` mapped from the host.
- **Fix**: Ensure `TS_USERSPACE=true` is present in your container environment.

#### 3. Ping fails to Tailscale IP
- **Expected Behavior**: In userspace networking mode, standard OS `ping` from the container host **will not work** because there is no Layer-3 kernel interface (`tailscale0`). Traffic must be proxied via SOCKS5/HTTP or accessed through `tailscale ssh`.
