# Rebuild Plex VM with SSH Keys from Day One

This guide walks through deleting the current Plex VM, rebuilding the Ubuntu template with SSH key fixes, and creating a fresh Plex VM that has SSH keys configured from the start.

## Prerequisites

- ✅ Image factory SSH key fixes are in place (already done)
- ✅ Your SSH public key exists at `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`
- ✅ Proxmox access configured
- ✅ Packer installed and configured

## Step 1: Delete Current Plex VM

### Option A: Via Proxmox Web UI

1. Go to Proxmox Web UI: `https://gpu01.specterrealm.com:8006`
2. Select **VM 102** (plex-vm-01)
3. Click **More** → **Remove**
4. Confirm deletion
5. **Important**: Also delete the disk if prompted

### Option B: Via Proxmox CLI

```bash
# SSH to GPU01
ssh root@gpu01.specterrealm.com

# Stop and delete VM 102
qm stop 102
qm destroy 102
```

## Step 2: Verify Your SSH Key Exists

```bash
# Check for your SSH public key
ls -la ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub

# Display your key (for verification)
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

The image factory will automatically find and use one of these keys.

## Step 3: Rebuild Ubuntu 24.04 Template

### 3.1 Navigate to Image Factory

```bash
cd /Users/michaelheaton/Projects/HomeLab/image-factory
```

### 3.2 Check Environment Variables

The build script uses environment variables. Check if you have a `.env` file or set them:

```bash
# Check for existing .env file
ls -la .env

# If you need to create one, copy from example:
# cp .env.example .env
# Then edit .env with your Proxmox credentials
```

Required variables:

- `PROXMOX_URL` - e.g., `https://gpu01.specterrealm.com:8006/api2/json`
- `PROXMOX_API_TOKEN_ID` - e.g., `packer@pam!packer-token`
- `PROXMOX_API_TOKEN_SECRET` - Your token secret
- `PROXMOX_NODE` - e.g., `GPU01`
- `PROXMOX_STORAGE_POOL` - e.g., `vmdks-iops` (optional, defaults to `vmdks`)
- `PROXMOX_NETWORK_BRIDGE` - e.g., `vmbr0` (optional, defaults to `vmbr0`)

### 3.3 Build the Template

```bash
# Make build script executable (if needed)
chmod +x build.sh

# Run the build script
./build.sh
```

**OR** use Packer directly:

```bash
cd packer/ubuntu-24.04

# Initialize Packer plugins
packer init ubuntu-24.04.pkr.hcl

# Validate configuration
packer validate ubuntu-24.04.pkr.hcl

# Build the template
packer build ubuntu-24.04.pkr.hcl
```

### 3.4 Verify Template Build

The build will:

1. Create a new VM (ID 900 by default)
2. Install Ubuntu 24.04
3. Run Ansible playbook (which includes SSH key setup)
4. Convert to template

**Expected output**: Template named `ubuntu-24.04-hardened-YYYYMMDD` (with today's date)

**Check in Proxmox**:

- Go to GPU01 → Templates
- You should see the new template with today's date

## Step 4: Create New Plex VM from Template

### 4.1 Clone Template to VM 102

**Via Proxmox Web UI**:

1. Right-click the new template → **Clone**
2. **VM ID**: `102`
3. **Name**: `plex-vm-01`
4. **Target Node**: `GPU01`
5. Click **Clone**

**Via Proxmox CLI**:

```bash
# SSH to GPU01
ssh root@gpu01.specterrealm.com

# Find the template ID (will be 900 or check Proxmox UI)
# Clone template 900 to VM 102
qm clone 900 102 --name plex-vm-01 --full
```

### 4.2 Configure VM Resources

**Via Proxmox Web UI**:

1. Select VM 102 → **Hardware**
2. **CPU**: 4 cores
3. **Memory**: 8192 MB (8 GB)
4. **Hard Disk**: Resize to 40 GB if needed, ensure storage is `vmdks-iops`
5. **Network Device 0 (net0)**:
   - Bridge: `vmbr0`
   - VLAN Tag: `10` (Production)
   - Model: `VirtIO`
6. **Network Configuration**:
   - **Note**: Only VLAN 10 interface - NFS access via Proxmox host routing (no VLAN 30 interface)
7. **GPU Passthrough** (if available):
   - Add PCI Device
   - Select GTX 1650 (PCI: 0a:00.0)
   - All Functions: Yes
   - Primary GPU: Yes

**Via Proxmox CLI**:

```bash
# Configure resources
qm set 102 --cores 4
qm set 102 --memory 8192
qm resize 102 scsi0 40G
qm set VM_ID --net0 virtio,bridge=vmbr0,tag=10
# Note: Only VLAN 10 - NFS access via Proxmox host routing

# GPU passthrough (GTX 1650)
qm set 102 --hostpci0 0a:00.0,pcie=1,rombar=0
```

### 4.3 Start VM

```bash
# Via CLI
qm start 102

# Or via Web UI: Select VM 102 → Start
```

## Step 5: Verify SSH Keys Work

Wait for the VM to boot (check console in Proxmox), then test SSH:

```bash
# The VM will get a DHCP IP initially (likely 172.16.10.100)
# Try SSH with your key (should work without password!)
ssh packer@172.16.10.100

# If that doesn't work, check the console for the actual IP
# Or check Proxmox Summary tab for the IP address
```

**Expected**: SSH should work immediately with your key - no password needed!

## Step 6: Run Ansible Playbook

Once SSH is working, configure the VM:

```bash
cd /Users/michaelheaton/Projects/HomeLab/plex/ansible

# Update inventory with current DHCP IP (if different from 172.16.10.100)
# Edit inventory/plex-vm.yml and update ansible_host if needed

# Run the playbook
ansible-playbook playbooks/deploy-plex-vm.yml
```

The playbook will:

- ✅ Configure static IP (172.16.10.20)
- ✅ Set up NFS mounts
- ✅ Install Plex Media Server
- ✅ Configure backups
- ✅ Set up firewall

**Note**: Since SSH keys are already configured, you don't need password auth!

## Step 7: Verify Everything Works

```bash
# Test static IP
ping plex-vm-01.specterrealm.com

# Test SSH
ssh packer@172.16.10.20

# Test Plex web UI
curl -I http://172.16.10.20:32400
```

## Troubleshooting

### SSH Still Requires Password

1. **Check if your SSH key was found during build**:

   - Look at the Packer/Ansible build output
   - Should see messages about finding SSH keys

2. **Verify key exists**:

   ```bash
   ls -la ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
   ```

3. **Check authorized_keys on VM**:

   ```bash
   # Via Proxmox console
   cat /home/packer/.ssh/authorized_keys
   ```

4. **If keys are missing**, the image factory should have kept password auth enabled. Check:
   ```bash
   # Via Proxmox console
   grep PasswordAuthentication /etc/ssh/sshd_config
   ```

### Template Build Fails

- Check Proxmox API token permissions
- Verify Ubuntu ISO exists in `isos` storage
- Check network connectivity to Proxmox
- Review Packer build logs

### VM Won't Start

- Check Proxmox logs: `journalctl -u pve-cluster -f`
- Verify resources are available (CPU, RAM, disk space)
- Check VM console for errors

## Success Criteria

✅ Template built successfully with today's date
✅ New Plex VM (102) created from template
✅ SSH works with key (no password) immediately
✅ Ansible playbook runs successfully
✅ Static IP configured (172.16.10.20)
✅ Plex web UI accessible

## Next Steps

After successful rebuild:

1. Follow `post-deployment-checklist.md` for Plex configuration
2. Add media libraries
3. Configure transcoding
4. Set up watch history sync (if desired)
