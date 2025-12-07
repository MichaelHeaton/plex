# Fix VM Routing - Emergency Recovery

If the Plex VM loses network connectivity after routing configuration changes, use this guide to restore connectivity.

## Problem

The VM cannot reach the gateway (172.16.10.1) or other networks, making it unreachable via SSH.

## Solution: Fix via Proxmox Console

1. **Access Proxmox Web UI**

   - Navigate to: `https://gpu01.specterrealm.com:8006`
   - Login with your credentials

2. **Open VM Console**

   - Go to: **Datacenter** → **GPU01** → **plex-vm-01** (VM 102)
   - Click **Console** tab
   - Login as `packer` user (or root if needed)

3. **Run Fix Script**

   Copy and paste this into the console:

   ```bash
   sudo bash << 'EOF'
   # Fix netplan configuration
   cat > /etc/netplan/01-netcfg.yaml << 'NETPLAN_EOF'
   network:
     version: 2
     renderer: networkd
     ethernets:
       enp6s18:  # VLAN 10 (Production)
         dhcp4: false
         addresses:
           - 172.16.10.20/24
         routes:
           - to: default
             via: 172.16.10.1
           # Route to storage network via Proxmox host
           - to: 172.16.30.0/24
             via: 172.16.10.10
         nameservers:
           addresses:
             - 172.16.10.2
             - 172.16.10.1
             - 1.1.1.1
   NETPLAN_EOF

   # Fix permissions
   chmod 600 /etc/netplan/01-netcfg.yaml

   # Apply netplan
   netplan apply

   # Verify routes
   echo "=== Current Routes ==="
   ip route show

   # Test connectivity
   echo ""
   echo "=== Testing Gateway Connectivity ==="
   ping -c 2 172.16.10.1 || echo "Gateway ping failed"
   ping -c 2 172.16.10.10 || echo "Proxmox host ping failed"
   EOF
   ```

4. **Verify Connectivity**

   After running the script, test:

   ```bash
   ping -c 2 172.16.10.1
   ping -c 2 172.16.10.10
   ```

5. **Re-run Ansible (if needed)**

   Once connectivity is restored, you can re-run the networking role:

   ```bash
   cd /Users/michaelheaton/Projects/HomeLab/plex/ansible
   ansible-playbook playbooks/deploy-plex-vm.yml -i inventory/plex-vm.yml --tags plex-networking
   ```

## Root Cause

The netplan file may have been corrupted or had incorrect permissions, preventing proper route configuration. The fix ensures:

- Default route via gateway (172.16.10.1)
- Storage network route via Proxmox host (172.16.10.10)
- Correct file permissions (600)

## Prevention

The Ansible role has been updated to use mode `0600` for the netplan file, which is the correct permission for netplan configuration files.
