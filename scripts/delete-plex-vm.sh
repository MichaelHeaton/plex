#!/bin/bash
# Script to delete Plex VM from Proxmox
# Usage: ./delete-plex-vm.sh [VM_ID]
# Example: ./delete-plex-vm.sh 102

set -e

PROXMOX_HOST="gpu01.specterrealm.com"
VM_ID="${1:-102}"  # Use first argument or default to 102

echo "⚠️  WARNING: This will DELETE VM ${VM_ID} (plex-vm-01) from Proxmox!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Connecting to Proxmox host..."
ssh root@${PROXMOX_HOST} << EOF
    echo "Stopping VM ${VM_ID}..."
    qm stop ${VM_ID} || true

    echo "Waiting for VM to stop..."
    sleep 5

    echo "Destroying VM ${VM_ID}..."
    qm destroy ${VM_ID}

    echo "✅ VM ${VM_ID} deleted successfully"
EOF

echo ""
echo "✅ Plex VM deleted. You can now rebuild the template and create a new VM."

