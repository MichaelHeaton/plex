# Plex VM Ansible Configuration

This directory contains Ansible playbooks and roles for deploying and managing the Plex Media Server VM.

## Structure

```
ansible/
├── playbooks/
│   └── deploy-plex-vm.yml      # Main deployment playbook
├── roles/
│   ├── plex-networking/         # Network configuration (hostname, static IP, firewall)
│   ├── plex-storage/            # NFS mounts and folder structure
│   ├── plex-install/            # Plex Media Server installation
│   └── plex-backup/             # Automated backup configuration
├── inventory/
│   └── plex-vm.yml              # VM inventory
├── ansible.cfg                   # Ansible configuration
└── README.md                     # This file
```

## Prerequisites

### 1. SSH Access

Before running Ansible, ensure SSH access to the VM:

```bash
# Add your SSH public key to the VM
# Option 1: Via Proxmox console
ssh root@<proxmox-host>
qm terminal 102

# Then in VM console:
sudo mkdir -p /home/packer/.ssh
sudo chmod 700 /home/packer/.ssh
# Copy your public key to /home/packer/.ssh/authorized_keys
sudo chmod 600 /home/packer/.ssh/authorized_keys
sudo chown -R packer:packer /home/packer/.ssh

# Option 2: Use ansible to add key (if password auth is temporarily enabled)
ansible-playbook playbooks/add-ssh-key.yml -k
```

### 2. NAS Shares

Ensure `/streaming` and `/backups` shares exist on NAS02 and are accessible from VLAN 30.

### 3. VM Configuration

- VM should be running
- VM should have two network interfaces:
  - net0: VLAN 10 (Production) - for service access
  - net1: VLAN 30 (Storage) - for NFS access

## Usage

### Deploy Plex VM

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex/ansible
ansible-playbook playbooks/deploy-plex-vm.yml
```

### Run Individual Roles

```bash
# Configure networking only
ansible-playbook playbooks/deploy-plex-vm.yml --tags networking

# Configure storage only
ansible-playbook playbooks/deploy-plex-vm.yml --tags storage

# Install Plex only
ansible-playbook playbooks/deploy-plex-vm.yml --tags install
```

## Configuration Details

### Network Configuration

- **Static IP**: 172.16.10.20 (VLAN 10)
- **Hostname**: plex-vm-01
- **Firewall**: UFW with SSH (22) and Plex (32400) allowed

### Storage Configuration

- **Streaming Mount**: `/mnt/streaming` (from NAS02 `/var/nfs/shared/streaming`)
- **Backups Mount**: `/mnt/backups` (from NAS02 `/var/nfs/shared/backups`)
- **Folder Structure**: Created automatically on `/mnt/streaming`

### Plex Configuration

- **Installation**: Via official Plex repository
- **User**: `plex` system user
- **Database**: `/var/lib/plexmediaserver/` (local disk)
- **Transcoding**: `/mnt/streaming/transcoding/`

### Backup Configuration

- **Automation**: Systemd timer (daily backups)
- **Location**: `/mnt/backups/databases/plex/`
- **Retention**: 14 days
- **Schedule**: Daily with randomized delay

## Post-Deployment

After running the playbook:

1. **Access Plex Web UI**: `http://172.16.10.20:32400`
2. **Claim Server**: Use Plex claim token
3. **Add Media Libraries**: Point to `/mnt/streaming/movies` and `/mnt/streaming/series`
4. **Configure Transcoding**: Enable hardware acceleration if GPU passthrough is working
5. **Set Network Settings**: Configure `PLEX_NO_AUTH_NETWORKS` for VLAN 10 and VLAN 5

## Troubleshooting

### NFS Mounts Fail

- Verify shares exist on NAS02
- Check NAS02 NFS export permissions for VLAN 30
- Verify VM has network interface on VLAN 30
- Test connectivity: `ping 172.16.30.4` from VM

### SSH Access Issues

- Ensure SSH keys are added to `/home/packer/.ssh/authorized_keys`
- Check UFW firewall allows SSH
- Verify VM is running and network is configured

### Plex Service Issues

- Check service status: `systemctl status plexmediaserver`
- Check logs: `journalctl -u plexmediaserver -f`
- Verify disk space: `df -h`
