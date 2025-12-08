# Plex Media Server

Plex Media Server deployment and configuration for the homelab.

## Deployment Options

### Current: Docker (NAS01)

- **Location**: NAS01 (Synology)
- **Image**: `ghcr.io/hotio/plex:latest`
- **Status**: Running (will remain during migration)
- **Configuration**: See `docker/compose.yaml`

### New: VM (Proxmox)

- **Location**: GPU01 (Proxmox)
- **VM Name**: `plex-vm-01`
- **VM ID**: Configurable (use next available ID, e.g., 102)
- **OS**: Ubuntu 24.04 LTS (hardened template)
- **Installation**: Native Plex Media Server
- **Status**: Deployed, configuration in progress
- **Configuration**: Managed via Ansible (see `ansible/`)

## Quick Start

### VM Deployment

1. **Prerequisites**:

   - Proxmox host (GPU01) has NFS mounts configured for `/streaming` and `/backups`
   - VM created from Ubuntu 24.04 hardened template
   - SSH access configured

2. **Deploy with Ansible**:

   ```bash
   cd ansible
   ansible-playbook playbooks/deploy-plex-vm.yml
   ```

3. **Access Plex**:
   - Web UI: `http://172.16.10.20:32400`
   - Claim server with Plex account
   - Add media libraries

## Directory Structure

```
plex/
├── ansible/                    # Ansible configuration
│   ├── playbooks/             # Deployment playbooks
│   ├── roles/                 # Ansible roles
│   │   ├── plex-networking/   # Network configuration
│   │   ├── plex-storage/      # NFS mounts and folders
│   │   ├── plex-install/      # Plex installation
│   │   └── plex-backup/       # Backup automation
│   └── inventory/             # VM inventory
├── docker/                     # Docker deployment (legacy)
│   ├── compose.yaml           # Docker Compose configuration
│   └── env.example            # Environment variables
├── docs/                       # Documentation
│   ├── vm-setup.md           # VM setup guide
│   ├── watch-history-sync.md  # Watch history migration
│   └── backup-strategy.md     # Backup and recovery
└── README.md                   # This file
```

## Configuration Management

All VM configuration is managed via Ansible in this repository:

- **Base OS**: Provided by `image-factory` (hardened Ubuntu 24.04 template)
- **Application Config**: Managed by Ansible roles in `ansible/roles/`

## Network Configuration

- **Service DNS**: `streaming.specterrealm.com` (via Traefik - ✅ configured)
- **Device DNS**: `plex-vm-01.specterrealm.com`
- **Static IP**: 172.16.10.20 (VLAN 10 - Production)
- **Storage Network**: VLAN 30 (for NFS access)

## Storage

- **Media**: `/mnt/streaming` (NFS from NAS02)
- **Backups**: `/mnt/backups/databases/plex/` (NFS from NAS02)
- **Database**: `/var/lib/plexmediaserver/` (local VM disk)

## Backup

- **Automation**: Systemd timer (daily backups)
- **Location**: `/mnt/backups/databases/plex/`
- **Retention**: 14 days
- **See**: `docs/backup-strategy.md` for details

## Migration from Docker

The old Plex server (Docker on NAS01) will remain running during migration:

1. Deploy new VM server
2. Configure and test
3. Sync watch history (optional - see `docs/watch-history-sync.md`)
4. Switch clients to new server
5. Decommission old server

## Documentation

- **VM Setup**: `docs/vm-setup.md` - Complete VM setup guide
- **Watch History**: `docs/watch-history-sync.md` - Migrating watch history
- **Backup Strategy**: `docs/backup-strategy.md` - Backup and recovery procedures
- **Ansible Usage**: `ansible/README.md` - Ansible playbook usage

## References

- [Plex Media Server Documentation](https://support.plex.tv/articles/)
- [Trash Guides](https://trash-guides.info/) - Plex optimization guides
- [Image Factory](../image-factory/) - Base VM template
- [Proxmox Infrastructure](../proxmox/) - Proxmox host configuration
