# Storage Access Options for Plex VM

## Current Situation

The Plex VM needs access to NFS shares (`/streaming` and `/backups`) but should NOT have direct VLAN 30 access.

## Option 1: VM Mounts NFS via Routing (Current Implementation)

**How it works:**

- VM has only VLAN 10 interface
- VM mounts NFS directly from NAS IP (172.16.30.4)
- Proxmox host routes VLAN 10 → VLAN 30 traffic
- VM uses static route: `172.16.30.0/24` via gateway

**Pros:**

- Standard NFS mount in VM
- Works with existing NFS setup
- VM sees shares as normal filesystems

**Cons:**

- VM still needs NFS client installed
- VM still mounts NFS (just via routing, not direct VLAN 30)

**Code:** Current `plex-storage` role is correct for this approach

## Option 2: Proxmox Storage Pools (Alternative)

**How it works:**

- Create NFS storage pools in Proxmox for `/streaming` and `/backups`
- Attach storage pools as additional disks to VM
- VM sees them as block devices (not NFS mounts)

**Pros:**

- VM doesn't need NFS client
- VM doesn't mount NFS directly
- Proxmox handles all NFS access

**Cons:**

- Requires creating new Proxmox storage pools
- VM sees block devices, not filesystems (would need formatting)
- More complex setup
- Less flexible (can't easily change mount points)

## Option 3: Remove NFS Mounts Entirely (Not Recommended)

**How it works:**

- VM doesn't mount NFS at all
- Plex database stored locally only
- Media would need to be accessed differently

**Pros:**

- Simplest (no NFS code)

**Cons:**

- Plex can't access media files
- Backups can't be stored on NAS
- Not practical for Plex use case

## Recommendation

**Option 1 (Current)** is the correct approach:

- VM mounts NFS via routing (no direct VLAN 30 access)
- Proxmox host routes the traffic
- This follows the security policy (only physical hosts have VLAN 30)

The current code in `plex-storage` role is correct - it mounts NFS from the NAS IP, and the Proxmox host routes that traffic from VLAN 10 to VLAN 30.

## If You Want Option 2

If you prefer Proxmox storage pools instead, we would need to:

1. Create Proxmox storage pools for streaming/backups
2. Attach them as disks to the VM during creation
3. Format and mount them in the VM
4. Remove NFS mount code from Ansible

This is more complex and less flexible. Option 1 is recommended.
