#!/bin/bash
# Script to create Plex VM from template
# Usage: ./create-plex-vm.sh [VM_ID] [TEMPLATE_ID]
# Example: ./create-plex-vm.sh 102 900

set -e

PROXMOX_HOST="gpu01.specterrealm.com"
VM_ID="${1:-102}"  # Use first argument or default to 102
TEMPLATE_ID="${2:-900}"  # Use second argument or default to 900
VM_NAME="plex-vm-01"

echo "Creating Plex VM from template..."
echo "  Template ID: ${TEMPLATE_ID}"
echo "  VM ID: ${VM_ID}"
echo "  VM Name: ${VM_NAME}"
echo ""

# Check if VM ID is already in use
if ssh root@${PROXMOX_HOST} "qm list | grep -qE '^[[:space:]]*${VM_ID}[[:space:]]'"; then
    echo "❌ Error: VM ID ${VM_ID} already exists!"
    echo "Please choose a different VM ID."
    exit 1
fi

# Check if template exists (template or stopped VM)
if ! ssh root@${PROXMOX_HOST} "qm list | grep -qE '^[[:space:]]*${TEMPLATE_ID}[[:space:]]'"; then
    echo "❌ Error: Template/VM ${TEMPLATE_ID} not found!"
    exit 1
fi

echo "✅ Template found, VM ID available"
echo ""

# Create VM from template
echo "Cloning template ${TEMPLATE_ID} to VM ${VM_ID}..."
ssh root@${PROXMOX_HOST} << EOF
    # Clone template
    qm clone ${TEMPLATE_ID} ${VM_ID} --name ${VM_NAME} --full

    # Configure resources
    echo "Configuring VM resources..."
    qm set ${VM_ID} --cores 4
    qm set ${VM_ID} --memory 8192
    qm resize ${VM_ID} scsi0 40G

    # Configure network (VLAN 10 for production, VLAN 30 for storage)
    echo "Configuring network..."
    qm set ${VM_ID} --net0 virtio,bridge=vmbr0,tag=10
    qm set ${VM_ID} --net1 virtio,bridge=vmbr1

    # GPU passthrough (GTX 1650)
    echo "Configuring GPU passthrough..."
    qm set ${VM_ID} --hostpci0 0a:00.0,pcie=1,rombar=0

    echo "✅ VM ${VM_ID} (${VM_NAME}) created and configured successfully"
    echo ""
    echo "Next steps:"
    echo "  1. Start the VM: qm start ${VM_ID}"
    echo "  2. Check VM IP in Proxmox Summary tab"
    echo "  3. Update plex/ansible/inventory/plex-vm.yml with the DHCP IP"
    echo "  4. Run Ansible playbook: cd plex/ansible && ansible-playbook playbooks/deploy-plex-vm.yml"
EOF

echo ""
echo "✅ Plex VM created! You can now start it and run the Ansible playbook."

