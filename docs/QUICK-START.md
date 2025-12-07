# Quick Start: Configure Plex VM

## Current Situation

- ✅ VM is running at `172.16.10.100` (DHCP)
- ❌ SSH keys not configured (password auth disabled)
- ❌ Static IP not configured

## Quick Fix (2 Steps)

### Step 1: Enable Password Auth (Proxmox Console)

Open Proxmox console for VM 102 and run these **3 short commands**:

```bash
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo systemctl status sshd
```

That's it! Just copy/paste those 3 lines.

### Step 2: Run Ansible Playbook

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex/ansible

# Uncomment the password line in inventory/plex-vm.yml first:
# ansible_ssh_pass: "packer"

# Then run the playbook
ansible-playbook playbooks/deploy-plex-vm.yml
```

The playbook will:

1. ✅ Add your SSH keys automatically
2. ✅ Disable password auth (security)
3. ✅ Configure static IP (172.16.10.20)
4. ✅ Set up NFS mounts
5. ✅ Install Plex
6. ✅ Configure backups

## After Playbook Completes

```bash
# Test access
ping plex-vm-01.specterrealm.com
ssh packer@172.16.10.20

# Access Plex web UI
open http://172.16.10.20:32400
```

## Image Factory Fix (For Future Builds)

The image factory has been updated to:

- ✅ Check for common SSH keys (`id_ed25519.pub`, `id_rsa.pub`, `vm-access-key.pub`)
- ✅ Keep password auth enabled if no keys found (with warning)
- ✅ Add all found SSH keys automatically

Next time you build an image, your SSH keys will be included automatically!
