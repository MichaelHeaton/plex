# Changes: VLAN 30 Removed from Plex VM

## Summary

The Plex VM configuration has been updated to remove direct VLAN 30 (Storage) access. The VM now only has VLAN 10 (Production) access, and NFS storage is accessed via Proxmox host routing.

## Changes Made

### 1. Network Configuration

**Before**:

- VM had 2 network interfaces:
  - net0: VLAN 10 (Production)
  - net1: VLAN 30 (Storage) - Direct NFS access

**After**:

- VM has 1 network interface:
  - net0: VLAN 10 (Production)
  - Static route added: `172.16.30.0/24` via gateway (Proxmox host routes to VLAN 30)

### 2. Security Policy

**Updated Policy** (documented in `specs-homelab/network/vlans.md`):

- **Physical hosts ONLY** have direct VLAN 30 access:
  - Proxmox nodes (GPU01, NUC01, NUC02)
  - Docker Swarm nodes (4x Pi5)
- **VMs/Containers** do NOT have direct VLAN 30 access:
  - VMs
  - LXC containers
  - Docker containers
  - Kubernetes pods
- **Storage Access**: VMs access NFS via host routing (VLAN 10 → VLAN 30)

### 3. Files Updated

#### Ansible Roles

- `ansible/roles/plex-networking/tasks/main.yml`:

  - Removed VLAN 30 interface configuration
  - Added static route to 172.16.30.0/24 via gateway
  - Updated comments

- `ansible/roles/plex-storage/tasks/main.yml`:
  - Updated comments to clarify routing approach

#### Documentation

- `docs/vm-setup.md`: Removed VLAN 30 references
- `docs/create-vm.md`: Removed VLAN 30 network interface
- `docs/vm-id-configuration.md`: New document explaining VM ID configuration
- `specs-homelab/network/vlans.md`: Added VLAN 30 access policy

### 4. VM ID Configuration

**Before**: Hardcoded to VM ID 102

**After**: Configurable - use next available VM ID

- Updated all documentation to use examples instead of hardcoded IDs
- Created `docs/vm-id-configuration.md` with guidance
- Updated scripts to accept VM ID as parameter

## Benefits

1. **Security**: Reduced attack surface - VMs don't have direct storage network access
2. **Simplified Firewall Rules**: Fewer NAS connections to manage
3. **Consistency**: All VMs follow same pattern (no direct VLAN 30 access)
4. **Flexibility**: VM ID is configurable, not hardcoded

## Migration Notes

If you have an existing Plex VM with VLAN 30:

1. **Remove VLAN 30 interface**:

   ```bash
   # Via Proxmox CLI
   qm set VM_ID --delete net1
   ```

2. **Update netplan** (will be done by Ansible):

   - Remove VLAN 30 interface configuration
   - Add static route to 172.16.30.0/24

3. **Verify NFS access still works**:
   ```bash
   # From VM
   mount | grep nfs
   # Should still show NFS mounts working via routing
   ```

## Static IP Configuration

**Note**: Proxmox does not support setting static IPs during VM creation (unless using cloud-init, which we're not using). The static IP (172.16.10.20) is configured via Ansible after VM creation.

**Process**:

1. Create VM → Gets DHCP IP automatically
2. Run Ansible playbook → Configures static IP 172.16.10.20

## Testing

After applying changes:

1. **Verify single network interface**:

   ```bash
   # From VM
   ip addr show
   # Should only show VLAN 10 interface
   ```

2. **Verify routing**:

   ```bash
   # From VM
   ip route show
   # Should show route to 172.16.30.0/24 via gateway
   ```

3. **Verify NFS access**:
   ```bash
   # From VM
   mount | grep nfs
   # Should show NFS mounts working
   ping 172.16.30.4  # Should work via routing
   ```
