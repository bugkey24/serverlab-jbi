# Architecture Overview: Clean Server Hosting Infrastructure

## 1. System Intent & Vision

This infrastructure design provides a modern, cloud-native hosting platform tailored specifically for **resource-constrained and restricted network environments** (such as university campus LXC containers, unprivileged VPS nodes, or firewalled private labs).

By moving away from traditional, monolithic LAMP stacks (Apache + MariaDB directly installed on the host OS), this architecture adopts containerization (Docker) and edge routing while solving two major operational restrictions:
1. **Absence of TUN/TAP network devices**: Resolves the lack of `/dev/net/tun` inside unprivileged containers by running Tailscale in userspace networking mode (SOCKS5/HTTP proxy).
2. **Absence of dedicated public IPv4 / Inbound Port Forwarding**: Eliminates dependency on static public IPs, complex campus port-forwarding requests, and path-prefix limitations (`/jbi24061/`) through Cloudflare Tunnels paired with Nginx Proxy Manager (NPM).

Additionally, this repository includes the **ServerLab Pulse** example application demonstrating:
- **Track 1**: Zero-CLI shared hosting simulation via Webmin and Adminer behind a subpath prefix.
- **Track 2**: Clean Docker VPS deployment with isolated component volumes and edge routing.

---

## 2. Directory Separation Standard

Following standard Linux Filesystem Hierarchy practices for modern infrastructure, services and data are divided into three isolated tiers:

```
/opt/
├── infra/        # Core infrastructure orchestration (this repository)
│   ├── docs/
│   ├── scripts/
│   └── services/
│       ├── cloudflared/
│       ├── npm/
│       └── tailscale/
├── apps/         # Independent application repositories (Laravel, Node, Python, etc.)
│   ├── demo-laravel-app/
│   └── other-app/
└── app-data/     # Persistent storage & state volumes
    # Pattern: /opt/app-data/{app-or-service}/{component-or-service}
    ├── cloudflared/
    │   └── config/
    ├── npm/
    │   ├── data/
    │   └── letsencrypt/
    ├── tailscale/
    │   └── state/
    └── demo-laravel-app/
        ├── database/
        └── storage/
```

### Volume Organization Standard: `/opt/app-data/{app-or-service}/{component-or-service}`
To keep data cleanly partitioned without collision:
- **Infrastructure Services**:
  - `/opt/app-data/npm/data`: NPM SQLite configuration database and runtime state.
  - `/opt/app-data/npm/letsencrypt`: SSL certificates and ACME challenges.
  - `/opt/app-data/tailscale/state`: Tailscale node identity and auth state.
  - `/opt/app-data/cloudflared/config`: Optional local tunnel credentials and configuration.
- **Applications (Example: `demo-laravel-app`)**:
  - `/opt/app-data/demo-laravel-app/database`: Database data directory (MariaDB / MySQL).
  - `/opt/app-data/demo-laravel-app/storage`: User uploads, cache, and runtime logs.

---

## 3. High-Level Architecture Diagram

```mermaid
flowchart TD
    subgraph Public_Internet [Public Internet / Remote Users]
        User[Browser Client]
        Admin[Developer / Admin via VPN]
    end

    subgraph Cloudflare_Edge [Cloudflare Edge Network]
        CF_DNS[DNS: *.yourdomain.com]
        CF_Edge[Cloudflare SSL Termination & DDoS Protection]
        CF_DNS --> CF_Edge
    end

    subgraph Campus_LXC [Campus Hosting LXC Container (1 vCPU, 1 GB RAM)]
        subgraph Docker_Bridge [Docker Bridge Network: infra_network]
            direction TB
            CFTunnel[Cloudflare Tunnel Container\ncloudflared]
            NPM[Nginx Proxy Manager\nReverse Proxy & SSL Router]
            Tailscale[Tailscale Userspace Container\nSOCKS5 Proxy :1055]
            
            App1[ServerLab Pulse App\ndemo-pulse-web & app]
        end

        subgraph Persistent_Storage [/opt/app-data/{app-or-service}/{component}]
            Data_NPM[(/opt/app-data/npm/data\n/opt/app-data/npm/letsencrypt)]
            Data_TS[(/opt/app-data/tailscale/state)]
            Data_Apps[(/opt/app-data/demo-laravel-app/database\n/opt/app-data/demo-laravel-app/storage)]
        end
    end

    %% Connections
    User -->|HTTPS :443| CF_DNS
    CF_Edge == Outbound Encrypted Tunnel (gRPC/QUIC) ==> CFTunnel
    CFTunnel -->|HTTP Internal| NPM
    NPM -->|Route / | App1

    Admin -->|SOCKS5 Proxy / SSH| Tailscale
    Tailscale -.->|Egress Internal Network| Docker_Bridge

    NPM -.-> Data_NPM
    Tailscale -.-> Data_TS
    App1 -.-> Data_Apps
```

---

## 4. Traffic Flow & Request Lifecycle

### Ingress Traffic (Public Users):
1. **DNS Resolution**: The user requests `pulse.yourdomain.com`. Cloudflare resolves this to its Edge Anycast IPs.
2. **Edge Security**: Cloudflare terminates public SSL, enforces WAF/bot security, and routes the traffic through an established zero-trust tunnel.
3. **Tunnel Ingress**: The `cloudflared` daemon inside Docker receives the payload via an outbound-initiated tunnel connection.
4. **Single-Entry Routing**: `cloudflared` passes incoming requests directly to Nginx Proxy Manager (`http://npm:80` on `infra_network`).
5. **Virtual Host & Subpath Dispatch**: NPM evaluates the hostname or URI path and forwards the request to the target application container.
6. **No Host Port Exposure Needed**: Because `cloudflared` communicates over the Docker internal bridge network directly with NPM, host port 80/443 does not strictly need to be exposed to the public internet, avoiding conflicts with host services.

### Egress & Management Traffic (Administrator):
1. Tailscale runs in userspace networking mode inside Docker, authenticating with the Tailscale control plane.
2. The administrator connects to their Tailnet from any computer or mobile device.
3. Using Tailscale SOCKS5 proxy or userspace SSH, the admin can manage the server, run commands, and access internal admin dashboards (like NPM Admin at port 81) securely without exposing admin ports to the public internet.

---

## 5. Security & Isolation Model

- **Least Privilege Execution**: Docker containers run isolated within user namespaces where feasible.
- **Zero Inbound Open Ports Required**: Because both Cloudflare Tunnel and Tailscale use outbound-only connections to Cloudflare and Tailscale coordination servers, no open inbound ports are required on campus firewalls.
- **Strict Network Isolation**: User apps communicate with NPM across the shared Docker bridge network (`infra_network`) using internal container hostnames.
