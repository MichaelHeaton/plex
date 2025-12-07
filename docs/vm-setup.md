# Plex VM Setup Documentation

## Overview

This document describes the setup and configuration of the Plex Media Server VM on Proxmox.

## VM Specifications

- **VM ID**: Configurable (not hardcoded - use next available ID)
- **Name**: plex-vm-01
- **Host Node**: GPU01
- **Template**: ubuntu-24.04-hardened-YYYYMMDD (VM ID 900)
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 40 GB (on `vmdks-iops` storage)
- **Network Interfaces**:
  - **net0**: VLAN 10 (Production) - Static IP: 172.16.10.20
  - **Note**: Only VLAN 10 interface - NFS access via Proxmox host routing (no direct VLAN 30 access)
- **GPU**: GTX 1650 (passthrough configured)

## Network Configuration

### VLAN 10 (Production)

- **IP**: 172.16.10.20 (static)
- **Gateway**: 172.16.10.1
- **DNS**: 172.16.15.1 (UniFi), 1.1.1.1 (Cloudflare)
- **Purpose**: Service access, Plex web UI

### Storage Access

- **Method**: NFS accessed via Proxmox host routing (VLAN 10 → VLAN 30)
- **Note**: VM does NOT have direct VLAN 30 access - follows security policy that only physical hosts have VLAN 30 access
- **Routing**: Proxmox host routes NFS traffic from VLAN 10 to VLAN 30

## Storage Configuration

### NFS Mounts

- **`/mnt/streaming`**: From NAS02 `/var/nfs/shared/streaming`
- **`/mnt/backups`**: From NAS02 `/var/nfs/shared/backups`

### Folder Structure

```
/mnt/streaming/
├── movies/
├── series/
├── downloads/
│   ├── torrents/
│   ├── usenet/
│   ├── completed/
│   └── staging/
└── transcoding/
```

## Deployment Steps

1. **Create VM from Template**

   - Clone template (VM ID 900) to new VM (use next available ID, e.g., 102)
   - Configure resources (CPU, RAM, disk, network, GPU)
   - **Network**: Only VLAN 10 interface (no VLAN 30)

2. **Configure VM** (Ansible)

   - Set hostname: `plex-vm-01`
   - Configure static IP: 172.16.10.20
   - Configure firewall (UFW)
   - System updates

3. **Configure Storage** (Ansible)

   - Mount NFS shares
   - Create folder structure

4. **Install Plex** (Ansible)

   - Add Plex repository
   - Install Plex Media Server
   - Configure service

5. **Configure Plex** (Manual)

   - Access web UI: `http://172.16.10.20:32400`
   - Claim server
   - Add media libraries
   - Configure transcoding

6. **Configure Backups** (Ansible)
   - Set up systemd timer
   - Test backup script

## Access

### Web UI

- **Direct**: `http://172.16.10.20:32400`
- **Via Traefik**: `https://streaming.specterrealm.com` (after Traefik rebuild)

### SSH

```bash
ssh packer@172.16.10.20
```

## GPU Passthrough

- **GPU**: GTX 1650 (PCI: 0a:00.0)
- **Status**: Configured in VM
- **Next Steps**: Install NVIDIA drivers in VM and verify with `nvidia-smi`

## Notes

- Old Plex server (NAS01 Docker) remains running during migration
- Watch history sync deferred until new server is operational
- Traefik routing will be configured after Docker Swarm rebuild
