# Enable Password Auth Temporarily (Quick Fix)

## Problem

Proxmox console doesn't support copy/paste well, making it impossible to add SSH keys manually.

## Solution: Enable Password Auth Temporarily

Run these commands in the Proxmox console (just a few short commands):

```bash
# 1. Enable password authentication temporarily
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 2. Restart SSH service
sudo systemctl restart sshd

# 3. Verify SSH is running
sudo systemctl status sshd
```

That's it! Now you can use Ansible with password authentication to add your SSH key.

## Next Steps

After enabling password auth, run the Ansible playbook which will:

1. Add your SSH key automatically
2. Disable password auth again (security)
3. Configure everything else

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex/ansible
ansible-playbook playbooks/deploy-plex-vm.yml
```
