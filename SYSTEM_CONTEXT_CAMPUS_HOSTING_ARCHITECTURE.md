# System Context & Architecture Brief: Campus Hosting Facility
**Document Type:** Infrastructure Context & Constraints Brief  
**Target Audience:** AI Agent / Automation Engineer  
**Purpose:** Provide foundational context for generating deployment configurations (Tailscale, Cloudflare Tunnel, Docker services) within a restricted LXC environment.  
**Status:** Baseline / Pre-Deployment

---

## 1. Executive Summary

This document describes the architecture, constraints, and operational realities of a hosting facility provided by a university department. The environment is an **Unprivileged LXC Container** running **TurnKey Linux (Debian 12)**, orchestrated by a **Proxmox VE** hypervisor. 

While the user has `root` access inside the container, the facility is **not a full VPS**. It is a pre-configured, security-restricted environment optimized for a single PHP/Laravel application. This document outlines why standard VPS operations (like native WireGuard, Tailscale with TUN, or unrestricted port binding) fail, and establishes the baseline for implementing workarounds (Userspace Tailscale, Cloudflare Tunnel, Dockerized services).

---

## 2. Infrastructure Topology

### 2.1 The Host Layer (Physical & Hypervisor)
- **Physical Server:** Owned and managed by the campus IT department.
- **Hypervisor:** Proxmox VE (Kernel: `6.17.4-2-pve`).
- **Public IP:** `103.164.60.5` (assigned to the host).
- **Reverse Proxy (Nginx Host):** The host runs a global Nginx instance that acts as the single entry point for all student containers.

### 2.2 The Container Layer (LXC)
- **Type:** Unprivileged LXC Container.
- **OS:** TurnKey GNU/Linux 18.0 (Debian 12/Bookworm).
- **Internal IP:** `192.168.11.16` (eth0).
- **Resource Limits:** 1 vCPU, 1 GB RAM, 1 GB Swap, 20 GB Storage.
- **User Mapping:** `root` (UID 0) inside the container is mapped to UID `100000` on the host (proven via `/proc/self/uid_map`).

### 2.3 The Application Layer
- **Default Stack:** TurnKey LAMP (Apache 2, MariaDB, PHP).
- **Control Panels:** Webmin (Port 10000), Adminer (Port 12322).
- **Application Root:** `/var/www/laravel/public` (configured in Apache Virtual Host).
- **Routing Mechanism:** Nginx Host forwards requests from `https://tajbi.poliwangi.ac.id/jbi24061/` to the LXC's internal IP on port 80.

---

## 3. Critical Constraints & Limitations

### 3.1 The TUN/TAP Restriction
- **Constraint:** The container lacks access to `/dev/net/tun`.
- **Impact:** Native WireGuard, OpenVPN (TUN mode), and Tailscale (standard mode) **cannot run**. They will fail with `CreateTUN: no such file or directory`.
- **Reason:** Proxmox security defaults for Unprivileged Containers.
- **Resolution Path:** Requires host-level configuration (`lxc.cgroup2.devices.allow` and `lxc.mount.entry`) by the campus admin.

### 3.2 The "Single Path" Routing Constraint
- **Constraint:** Nginx Host is configured with a specific `location /jbi24061/` block.
- **Impact:** The container is not a "public internet endpoint." All external traffic must pass through this specific path. Adding new applications requires either:
  - Configuring a local Reverse Proxy (e.g., Nginx Proxy Manager) to handle sub-paths *inside* the container.
  - Requesting the admin to add new `location` blocks on the host.

### 3.3 Port Binding Conflicts
- **Constraint:** Only one service can bind to port 80/443 at a time.
- **Impact:** Running Apache (LAMP) and Docker (Nginx Proxy Manager) simultaneously will cause port conflicts. The user must explicitly stop one to run the other.

### 3.4 Resource Scarcity
- **Constraint:** 1 GB RAM total.
- **Impact:** Running multiple Docker containers (e.g., Database + App + Reverse Proxy) requires careful memory management. OOM (Out of Memory) kills are a high risk.

---

## 4. Operational Workarounds & Strategies

### 4.1 VPN Strategy: Tailscale Userspace Mode
Since TUN is unavailable, Tailscale must be run in **Userspace Networking Mode**.
- **Mechanism:** `tailscaled --tun=userspace-networking`.
- **Behavior:** Operates as a SOCKS5/HTTP proxy (default `localhost:1055`).
- **Requirement:** Applications must be explicitly configured to use the proxy (e.g., `ALL_PROXY=socks5://localhost:1055`).
- **Limitation:** Not a transparent VPN; cannot act as an exit node or subnet router.

### 4.2 External Exposure Strategy: Cloudflare Tunnel
To bypass the Nginx Host (and its path restrictions) without needing a public IP or TUN.
- **Mechanism:** `cloudflared` daemon runs inside the container, establishing an outbound-only connection to Cloudflare Edge.
- **Benefit:** Bypasses campus Nginx entirely; provides automatic SSL.
- **Limitation:** Traffic routes through Cloudflare (bandwidth overhead); not suitable for large media streaming (100MB upload limit on free tier).

### 4.3 Multi-Service Strategy: Docker & Nginx Proxy Manager (NPM)
- **Current State:** Docker is installed. NPM is deployed via Docker Compose.
- **Logic:** NPM acts as an internal reverse proxy. The campus Nginx Host forwards *all* `/jbi24061/*` traffic to NPM (port 80). NPM then routes based on sub-paths (e.g., `/jbi24061/app2/`) to internal Docker containers.
- **Requirement:** Campus Nginx must be configured to forward the prefix without stripping it (or NPM must handle the path rewrite).

---

## 5. Baseline Configuration State (As of Document Creation)

- **Apache:** Active (Port 80). Serving `/var/www/laravel/public`.
- **MariaDB:** Active (Port 3306).
- **Docker:** Installed and running.
- **NPM:** Deployed (but stopped to allow Apache to run).
- **Webmin/SSH:** Accessible (Port 10000 / Port 24061).
- **TUN:** **Not available**.
- **Cloudflare Tunnel:** **Not installed**.

---

## 6. Instructions for AI Agent (Next Steps)

Based on this context, the AI Agent should generate:
1.  **Tailscale Setup Guide:** Step-by-step commands to install and run Tailscale in userspace mode, including how to configure Laravel/CLI tools to use the SOCKS5 proxy.
2.  **Cloudflare Tunnel Setup Guide:** Commands to install `cloudflared`, authenticate, and create a tunnel that maps a custom domain to the internal services (e.g., NPM or Laravel).
3.  **Docker Compose Blueprint:** A production-ready `docker-compose.yml` that runs NPM and a placeholder Laravel app, ensuring port 80 is managed correctly (stopping Apache first).
4.  **Migration Plan:** Steps to safely transition from the native LAMP stack to a fully Dockerized environment without losing data.

---

## 7. Glossary of Terms
- **LXC:** Linux Containers (OS-level virtualization).
- **TUN:** Virtual network kernel device (Layer 3).
- **NPM:** Nginx Proxy Manager (Dockerized reverse proxy).
- **Unprivileged Container:** A container where root is mapped to a non-root user on the host.
