#!/bin/bash
# Fix VM Routing - Run this from Proxmox console or via qemu-guest-agent
# This restores the default gateway route that may have been broken

# Fix netplan configuration
cat > /etc/netplan/01-netcfg.yaml << 'EOF'
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
EOF

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

