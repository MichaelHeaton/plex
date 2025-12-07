# Create Plex VM on Proxmox

## Quick Start

The VM needs to be created from the Ubuntu 24.04 hardened template before running the Ansible playbook.

## Option 1: Proxmox Web UI (Recommended)

1. **Access Proxmox Web UI**: `https://gpu01.specterrealm.com:8006`

2. **Clone Template**:

   - Navigate to **GPU01** node
   - Find template **VM 100** (ubuntu-24.04-hardened) or **VM 900** (if it exists)
   - Right-click → **Clone**
   - **VM ID**: Use next available ID (e.g., `102` if available)
   - **Name**: `plex-vm-01`
   - **Target Node**: `GPU01`
   - Click **Clone**

3. **Configure VM Resources**:

   - Select your VM → **Hardware**
   - **CPU**: 4 cores
   - **Memory**: 8192 MB (8 GB)
   - **Hard Disk**:
     - If not 40GB, resize to 40 GB
     - Storage: `vmdks-iops`
   - **Network Device 0 (net0)**:
     - Bridge: `vmbr0`
     - VLAN Tag: `10` (Production)
     - Model: `VirtIO`
     - **Note**: Only VLAN 10 interface - NFS access via Proxmox host routing
   - **GPU Passthrough** (if available):
     - Add PCI Device
     - Select GTX 1650 (PCI: 0a:00.0)
     - All Functions: Yes
     - Primary GPU: Yes

4. **Start VM**:

   - Select your VM → **Start**

5. **Wait for VM to Boot**:
   - Check console to ensure it boots successfully
   - VM will get a DHCP IP initially (likely 172.16.10.100)

## Option 2: Proxmox CLI

```bash
# SSH to GPU01
ssh root@gpu01.specterrealm.com

# Clone template (replace TEMPLATE_ID and VM_ID with your values)
# Example: Clone template 900 to VM 102
qm clone TEMPLATE_ID VM_ID --name plex-vm-01 --full

# Configure resources (replace VM_ID with your VM ID)
qm set VM_ID --cores 4
qm set VM_ID --memory 8192
qm resize VM_ID scsi0 40G
qm set VM_ID --net0 virtio,bridge=vmbr0,tag=10
# Note: Only VLAN 10 - NFS access via Proxmox host routing

# Configure GPU passthrough (GTX 1650)
qm set 102 --hostpci0 0a:00.0,pcie=1,rombar=0

# Start VM
qm start 102
```

## Verify VM is Running

```bash
# From Proxmox host
qm status 102

# Should show: status: running
```

## Next Steps

After the VM is created and running:

1. **Update Ansible Inventory** (if needed):

   - The VM will initially have a DHCP IP (check Proxmox console)
   - Update `plex/ansible/inventory/plex-vm.yml` with the current IP
   - Or wait for Ansible to configure static IP 172.16.10.20

2. **Run Ansible Playbook**:

   ```bash
   cd /Users/michaelheaton/Projects/HomeLab/plex/ansible
   ansible-playbook playbooks/deploy-plex-vm.yml
   ```

3. **Verify Access**:
   ```bash
   # After Ansible configures static IP
   ping plex-vm-01.specterrealm.com
   ssh packer@172.16.10.20
   ```

## Troubleshooting

### Template Not Found

- Check which template VM IDs exist: `qm list | grep template`
- Template might be VM 100 or VM 900
- Update clone command accordingly

### VM Won't Start

- Check Proxmox logs: `journalctl -u pve-cluster -f`
- Check VM console in Proxmox web UI
- Verify template is not corrupted

### Network Issues

- Verify VLAN 10 is configured on vmbr0
- Check Proxmox network configuration
