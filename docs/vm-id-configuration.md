# VM ID Configuration

## Overview

The Plex VM ID is **not hardcoded** - you can use any available VM ID when creating the VM. The Ansible playbook and documentation use examples, but you should use the next available ID in your Proxmox cluster.

## Finding Available VM ID

### Via Proxmox Web UI

1. Go to Proxmox Web UI
2. Check existing VMs to see which IDs are in use
3. Use the next available ID (typically 100-899 range for regular VMs)

### Via Proxmox CLI

```bash
ssh root@gpu01.specterrealm.com
qm list | awk '{print $1}' | grep -E '^[0-9]+$' | sort -n
```

This shows all used VM IDs. Pick the next available one.

## Recommended VM ID Ranges

- **100-899**: Regular VMs (use for Plex)
- **900+**: Templates (reserved)
- **Avoid**: IDs already in use

## Example: Using VM ID 102

If VM ID 102 is available:

```bash
# Clone template
qm clone 900 102 --name plex-vm-01 --full

# Configure (using VM ID 102)
qm set 102 --cores 4
qm set 102 --memory 8192
# ... etc
```

## Example: Using Different VM ID

If you want to use VM ID 150:

```bash
# Clone template
qm clone 900 150 --name plex-vm-01 --full

# Configure (using VM ID 150)
qm set 150 --cores 4
qm set 150 --memory 8192
# ... etc
```

## Ansible Inventory

Update `plex/ansible/inventory/plex-vm.yml` with the actual VM IP address (not the VM ID):

```yaml
plex-vm-01:
  ansible_host: 172.16.10.100 # Current DHCP IP (will change to static 172.16.10.20)
```

The VM ID is only used during VM creation in Proxmox, not in Ansible.

## Static IP Configuration

The static IP (172.16.10.20) is configured via Ansible, not at VM creation time. Proxmox doesn't support setting static IPs during VM creation for our setup (we're not using cloud-init).

**Process**:

1. Create VM (gets DHCP IP automatically)
2. Run Ansible playbook (configures static IP 172.16.10.20)

## Notes

- VM ID is only relevant for Proxmox VM management
- Ansible uses IP addresses, not VM IDs
- Static IP is configured post-creation via Ansible
- DNS records use the static IP, not VM ID
