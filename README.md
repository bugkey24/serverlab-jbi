<div align="center">

# Campus Hosting Core Infrastructure
### Zero-TUN Tailscale • Cloudflare Tunnel • Nginx Proxy Manager • Clean Architecture

[![Docker](https://img.shields.io/badge/Docker-Compose_v2-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Userspace_Mode-4964ED?style=for-the-badge&logo=tailscale&logoColor=white)](https://tailscale.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare_Tunnel-Zero_Trust-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://www.cloudflare.com/products/tunnel/)
[![Nginx Proxy Manager](https://img.shields.io/badge/Nginx_Proxy_Manager-v2.11+-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginxproxymanager.com/)
[![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net/)
[![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)](https://getbootstrap.com/)
[![Debian](https://img.shields.io/badge/Debian-12_(Bookworm)-A81D33?style=for-the-badge&logo=debian&logoColor=white)](https://www.debian.org/)
[![Proxmox](https://img.shields.io/badge/Proxmox_VE-Unprivileged_LXC-E57000?style=for-the-badge&logo=proxmox&logoColor=white)](https://www.proxmox.com/)

<p align="center">
  A production-ready blueprint for deploying multi-tenant applications in restricted, unprivileged LXC containers and institutional campus networks without public IPv4 addresses, TUN devices, or firewall ingress privileges.
</p>

[Architecture](docs/ARCHITECTURE.md) • [Demo App](examples/demo-laravel-app/README.md) • [Track 1 (Webmin)](examples/demo-laravel-app/TRACK1_MANUAL_WEBMIN_GUIDE.md) • [Track 2 (Docker VPS)](examples/demo-laravel-app/TRACK2_DOCKER_VPS_GUIDE.md) • [Troubleshooting](docs/TROUBLESHOOTING.md)

</div>

---

## 📖 Context & Problem Statement

In academic, institutional, or unprivileged container environments (e.g., TurnKey Linux / Debian 12 on Proxmox VE), developers face critical operational limitations:

1. **No Kernel TUN Device**: Unprivileged containers cannot access `/dev/net/tun`, causing native WireGuard, OpenVPN, and standard Tailscale to fail immediately.
2. **Restricted Ingress & Shared Public IP**: Containers reside behind institutional NAT firewalls and host-level reverse proxies, often limited to an assigned subpath (e.g. `https://campus.domain.edu/student-id/`). Hosting multiple apps, custom subdomains, or external APIs is impossible through traditional means.
3. **Severe Resource Ceiling**: Containers operate under strict limits (e.g. 1 vCPU, 1 GB RAM). Monolithic stacks (Apache + MySQL + dev tools) quickly trigger Out-Of-Memory (OOM) kills.

### The Clean Architecture Solution
This repository transforms a restricted container into a modern hosting node by decoupling infrastructure into modular, self-contained services:
- **Tailscale in Userspace Mode**: Uses Go's internal `netstack` to establish private mesh networking, SOCKS5 proxying, and secure SSH without needing `/dev/net/tun`.
- **Cloudflare Tunnel (`cloudflared`)**: Creates outbound-only, encrypted QUIC connections to Cloudflare's Edge, providing custom domain routing, SSL termination, and DDoS protection with zero inbound open firewall ports.
- **Nginx Proxy Manager (NPM)**: Consolidated internal reverse proxy powered by SQLite (< 70MB RAM), managing dynamic routing and custom subdomains from an intuitive UI.
- **ServerLab Pulse (Demo Project)**: A responsive PHP & Bootstrap application proving dual deployment pathways:
  - **Track 1**: Zero-CLI shared hosting simulation via Webmin and Adminer behind a campus subpath (`/jbi24061/`).
  - **Track 2**: Full Docker VPS deployment with isolated component volumes and Cloudflare Tunnel routing.

---

## 🏗️ Architecture Topology

```mermaid
flowchart TD
    subgraph Clients [Public Internet & Developers]
        WebUsers[End Users / Browsers]
        Admin[Developer / Admin via Tailnet]
    end

    subgraph Cloudflare_Edge [Cloudflare Edge Network]
        CF_DNS["DNS: *.yourdomain.com"]
        CF_Edge[Cloudflare SSL Termination & WAF]
        CF_DNS --> CF_Edge
    end

    subgraph LXC_Container ["Campus LXC Container (1 vCPU, 1 GB RAM)"]
        subgraph Docker_Network [Docker Network: infra_network]
            direction TB
            CFTunnel[Cloudflare Tunnel\ncloudflared]
            NPM[Nginx Proxy Manager\nInternal Router :80]
            Tailscale[Tailscale Userspace\nSOCKS5 :1055 & SSH]
            
            App1[ServerLab Pulse App\ndemo-pulse-web & app]
            App2[Other Application 2\ne.g. Next.js / API]
        end

        subgraph Storage_Layer [Storage Volumes: /opt/app-data/{app-or-service}/{component}]
            Data_NPM[(npm/data\nnpm/letsencrypt)]
            Data_TS[(tailscale/state)]
            Data_Apps[(demo-laravel-app/database\ndemo-laravel-app/storage)]
        end
    end

    %% Routing
    WebUsers -->|HTTPS :443| CF_DNS
    CF_Edge == Outbound QUIC Tunnel ==> CFTunnel
    CFTunnel -->|HTTP / Forward Host| NPM
    NPM -->|Route pulse.yourdomain.com| App1
    NPM -->|Route api.yourdomain.com| App2

    Admin -->|Tailscale SSH / SOCKS5| Tailscale
    Tailscale -.->|Private Access| Docker_Network

    NPM -.-> Data_NPM
    Tailscale -.-> Data_TS
    App1 -.-> Data_Apps
    App2 -.-> Data_Apps
```

---

## 📂 Standard Directory Hierarchy

Each service and application is isolated with its own modern Compose specification file (`compose.yaml`) and dedicated `.env` configuration file. Persistent volume storage is structured strictly by component:

```text
/opt/
├── infra/                  <-- Core infrastructure repository
│   ├── docs/               <-- Comprehensive guides & runbooks
│   ├── scripts/            <-- Automation & diagnostic scripts
│   └── services/           <-- Modular, independently managed services
│       ├── cloudflared/
│       │   ├── compose.yaml
│       │   ├── .env.example
│       │   └── README.md
│       ├── npm/
│       │   ├── compose.yaml
│       │   ├── .env.example
│       │   └── README.md
│       └── tailscale/
│           ├── compose.yaml
│           ├── .env.example
│           └── README.md
├── apps/                   <-- Application source repositories
│   └── demo-laravel-app/   <-- ServerLab Pulse Demo Application
│       ├── src/            <-- Application source code
│       ├── docker/         <-- Container definitions
│       ├── simulation/     <-- Local Docker simulation suite
│       └── compose.yaml    <-- Track 2 Compose manifest
└── app-data/               <-- Centralized persistent volumes
    # Pattern: /opt/app-data/{app-or-service}/{component-or-service}
    ├── cloudflared/
    │   └── config/
    ├── npm/
    │   ├── data/           <-- NPM SQLite database & dynamic configs
    │   └── letsencrypt/    <-- SSL certificates & challenges
    ├── tailscale/
    │   └── state/          <-- Tailscale node keys & state
    └── demo-laravel-app/
        ├── database/       <-- DB data files (MariaDB / MySQL)
        └── storage/        <-- Application uploads & persistent files
```

---

## 🚀 Quick Start Guide

### Step 1: Clone Repository to `/opt/infra`
```bash
sudo git clone https://github.com/bugkey24/serverlab-jbi.git /opt/infra
cd /opt/infra
```

### Step 2: Initialize Directories & Network
Run the automated initialization script:
```bash
chmod +x scripts/*.sh
sudo ./scripts/init-infra.sh
```

### Step 3: Configure and Start Each Core Service

#### 1. Nginx Proxy Manager (NPM)
```bash
cd /opt/infra/services/npm
nano .env
docker compose up -d
```

#### 2. Cloudflare Tunnel
```bash
cd /opt/infra/services/cloudflared
nano .env
docker compose up -d
```

#### 3. Tailscale Userspace
```bash
cd /opt/infra/services/tailscale
nano .env
docker compose up -d
```

---

## 🧪 Testing & Validation Tracks

This repository includes a complete demonstration project located at [`examples/demo-laravel-app/`](examples/demo-laravel-app/README.md) designed to test and compare both deployment methods:

| Feature | Track 1: Webmin & Adminer (Shared-Hosting) | Track 2: Full Docker VPS |
| :--- | :--- | :--- |
| **Guide** | [TRACK1_MANUAL_WEBMIN_GUIDE.md](examples/demo-laravel-app/TRACK1_MANUAL_WEBMIN_GUIDE.md) | [TRACK2_DOCKER_VPS_GUIDE.md](examples/demo-laravel-app/TRACK2_DOCKER_VPS_GUIDE.md) |
| **Interface** | Webmin File Manager (`:10000`) & Adminer (`:12322`) | Docker Compose (`compose.yaml`) & NPM UI |
| **Access Requirement** | Zero terminal / No SSH required | Terminal / Docker access |
| **Routing** | Campus subpath (`https://tajbi.poliwangi.ac.id/jbi24061/`) | Clean custom root domain (`https://pulse.yourdomain.com/`) |
| **Local Preview** | `cd examples/demo-laravel-app/simulation && docker compose up -d` | `cd examples/demo-laravel-app && docker compose up -d` |

---

## 📚 In-Depth Documentation Index

| Document | Topic | Description |
| :--- | :--- | :--- |
| [**Architecture Overview**](docs/ARCHITECTURE.md) | System Design | Detailed traffic flow, security isolation, and storage topology. |
| [**Tailscale Userspace**](docs/TAILSCALE_USERSPACE.md) | Private VPN | Overcoming lack of `/dev/net/tun`, SOCKS5 proxying, and Tailscale SSH. |
| [**Cloudflare Tunnel**](docs/CLOUDFLARE_TUNNEL.md) | Edge Ingress | Bypassing campus firewalls, wildcard routing into NPM, and custom domains. |
| [**Nginx Proxy Manager**](docs/NGINX_PROXY_MANAGER.md) | Traffic Dispatcher | SQLite low-memory setup, SSL termination, and application proxying. |
| [**LAMP to Docker Migration**](docs/MIGRATION_LAMP_TO_DOCKER.md) | Migration Runbook | Step-by-step database dump, Apache deactivation, and rollback plan. |
| [**Troubleshooting Guide**](docs/TROUBLESHOOTING.md) | Diagnostics & Fixes | Port conflicts, OOM mitigation, buffer sizing, and diagnostic commands. |

---

## 🔒 Security Best Practices

- **Never Commit Secrets**: The `.gitignore` is configured to prevent `.env` across all directories, credentials, state files, and runtime volumes from ever entering git.
- **Admin UI Isolation**: The Nginx Proxy Manager admin UI is bound exclusively to `127.0.0.1:81`. It is never exposed to the public internet. Access it only through Tailscale or an SSH tunnel (`ssh -L 8181:localhost:81 user@host`).
- **Ephemeral & Tagged VPN Keys**: Generate Tailscale keys tagged specifically for servers with strict ACL permissions.
