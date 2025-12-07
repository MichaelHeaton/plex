# Add SSH Key to Plex VM

## Quick Fix: Add SSH Key via Proxmox Console

Since the VM only accepts SSH key authentication, you need to add your SSH key via the Proxmox console first.

### Steps:

1. **Access Proxmox Console**:

   - Go to Proxmox Web UI: `https://gpu01.specterrealm.com:8006`
   - Select VM 102 (plex-vm-01)
   - Click **Console** tab
   - Login as `packer` user (or use the password if still enabled)

2. **Add Your SSH Public Key**:

   ```bash
   # Create .ssh directory if it doesn't exist
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh

   # Add your SSH public key (replace with your actual key)
   echo "YOUR_SSH_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

3. **Get Your SSH Public Key** (from your Mac):

   ```bash
   # Use your preferred key (ed25519 or rsa)
   cat ~/.ssh/id_ed25519.pub
   # or
   cat ~/.ssh/id_rsa.pub
   ```

4. **Copy the entire output** and paste it into the `echo` command above in the Proxmox console.

### Alternative: Use Ansible with Password Auth (Temporary)

If password authentication is still enabled, you can temporarily use it with Ansible:

1. **Update inventory to use password**:

   ```yaml
   plex-vm-01:
     ansible_host: 172.16.10.100
     ansible_user: packer
     ansible_ssh_pass: "packer" # Temporary password
     ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
   ```

2. **Run Ansible playbook** - it will add your SSH key automatically

3. **Remove password from inventory** after first run

### After Adding SSH Key

Once your SSH key is added, you can:

1. **Test SSH connection**:

   ```bash
   ssh packer@172.16.10.100
   ```

2. **Run Ansible playbook**:
   ```bash
   cd /Users/michaelheaton/Projects/HomeLab/plex/ansible
   ansible-playbook playbooks/deploy-plex-vm.yml
   ```

The playbook will:

- Configure static IP (172.16.10.20)
- Set up NFS mounts
- Install Plex
- Configure backups
