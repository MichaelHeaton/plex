# Quick Rebuild Checklist

## ✅ Step 1: Delete Current Plex VM

**Option A - Script**:

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex
./scripts/delete-plex-vm.sh
```

**Option B - Manual**:

- Proxmox Web UI → VM 102 → More → Remove
- Or: `ssh root@gpu01.specterrealm.com` → `qm destroy 102`

## ✅ Step 2: Verify SSH Key Exists

```bash
ls -la ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
```

At least one should exist. The image factory will use it automatically.

## ✅ Step 3: Rebuild Template

```bash
cd /Users/michaelheaton/Projects/HomeLab/image-factory

# Check/configure environment variables
# Edit packer/.env if needed

# Build template
./build.sh
```

**Expected**: Template `ubuntu-24.04-hardened-YYYYMMDD` created (takes ~15-20 minutes)

## ✅ Step 4: Create New Plex VM

**Via Proxmox Web UI**:

1. Right-click new template → Clone
2. VM ID: `102`, Name: `plex-vm-01`
3. Configure: 4 CPU, 8GB RAM, 40GB disk
4. Network: VLAN 10 only (NFS via Proxmox host routing)
5. GPU: GTX 1650 passthrough
6. Start VM

**Via CLI** (see full guide for commands)

## ✅ Step 5: Test SSH (Should Work Immediately!)

```bash
# VM will get DHCP IP (check Proxmox Summary tab)
ssh packer@172.16.10.100  # or whatever IP it gets
```

**Expected**: SSH works with your key - no password needed! 🎉

## ✅ Step 6: Run Ansible Playbook

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex/ansible

# Update inventory/plex-vm.yml with current DHCP IP if needed

# Run playbook
ansible-playbook playbooks/deploy-plex-vm.yml
```

## ✅ Step 7: Verify

```bash
ping plex-vm-01.specterrealm.com
ssh packer@172.16.10.20
curl -I http://172.16.10.20:32400
```

## 🎯 Success!

If SSH worked in Step 5, the image factory fix is working! 🚀
