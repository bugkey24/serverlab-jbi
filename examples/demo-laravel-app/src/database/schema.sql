-- ServerLab Pulse: Initial Schema
-- For manual import via Adminer / phpMyAdmin / Webmin or auto-init in Docker

CREATE TABLE IF NOT EXISTS `server_nodes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `node_name` VARCHAR(100) NOT NULL,
  `environment` VARCHAR(50) NOT NULL DEFAULT 'production',
  `service_role` VARCHAR(100) NOT NULL,
  `ip_address` VARCHAR(45) NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample Seed Data
INSERT INTO `server_nodes` (`node_name`, `environment`, `service_role`, `ip_address`, `notes`)
VALUES
('campus-lxc-node', 'TurnKey Debian 12', 'Edge Hypervisor Gateway', '192.168.11.16', 'Default campus LXC student instance (1 vCPU, 1 GB RAM).'),
('cloudflare-tunnel', 'Zero Trust Edge', 'Outbound Ingress Tunnel', 'Anycast Edge', 'Encrypted tunnel forwarding *.yourdomain.com into NPM.'),
('nginx-proxy-manager', 'Docker Container', 'Central Reverse Proxy & SSL', '172.20.0.10', 'Handles internal routing and domain dispatch.')
ON DUPLICATE KEY UPDATE `node_name` = `node_name`;
