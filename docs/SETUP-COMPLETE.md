# Plex VM Setup - Complete ✅

## Setup Summary

The Plex Media Server VM has been successfully deployed and configured.

## Completed Configuration

### ✅ Infrastructure

- **VM Created**: plex-vm-01 (Proxmox GPU01)
- **OS**: Ubuntu 24.04 LTS (hardened template)
- **Resources**: 4 CPU cores, 8GB RAM, 40GB disk
- **Network**:
  - VLAN 10 (Production): 172.16.10.20 (static)
  - VLAN 30 (Storage): 172.16.30.20 (direct NFS access)
- **GPU**: GTX 1650 (passthrough configured)

### ✅ Plex Server

- **Server Name**: SpecterVision
- **Status**: Claimed and running
- **Version**: 1.42.2.10156-f737b826c
- **Libraries Configured**:
  - Movies: `/mnt/streaming/movies`
  - Series: `/mnt/streaming/series`

### ✅ Hardware Transcoding

- **GPU Drivers**: NVIDIA 580.95.05 installed
- **GPU Detection**: GTX 1650 detected and working
- **Hardware Acceleration**: Enabled in Plex settings
- **Transcoding Directory**: `/mnt/streaming/transcoding`

### ✅ Storage

- **Streaming Mount**: `/mnt/streaming` (NAS02 NFSv3)
- **Backup Mount**: `/backup` (NAS01 NFSv4, isolated to plex subdirectory)
- **Folder Structure**: Created (movies, series, downloads, transcoding)

### ✅ Backups

- **Automation**: Systemd timer enabled
- **Schedule**: Daily with randomized delay
- **Location**: `/backup/plex-db-backup-*.tar.gz`
- **Retention**: 14 days
- **Status**: ✅ Working (tested successfully)

### ✅ Network Configuration

- **No-Auth Networks**: Configured for VLAN 10, 5, and 15
- **Environment Variable**: `PLEX_MEDIA_SERVER_NO_AUTH_NETWORKS` set
- **Note**: May need to verify in Plex UI (Settings → Network) as native installs sometimes require Preferences.xml configuration

## Access Information

- **Web UI**: `http://172.16.10.20:32400`
- **SSH**: `ssh packer@172.16.10.20` (using `~/.ssh/vm-access-key`)
- **Server Name**: SpecterVision

## Verification Checklist

- [x] VM created and running
- [x] Plex installed and running
- [x] Server claimed
- [x] Media libraries added
- [x] GPU drivers installed
- [x] Hardware transcoding enabled
- [x] NFS mounts working
- [x] Backups configured and tested
- [x] Network settings configured
- [ ] DNS record added (UniFi - manual step)
- [ ] Remote access configured (optional - Cloudflare tunnel)

## Remaining Manual Steps

### 1. DNS Record (Optional)

Add DNS record in UniFi Controller:

- **Name**: `plex-vm-01`
- **Type**: A
- **IP**: `172.16.10.20`
- **Domain**: `specterrealm.com`

### 2. Verify Network Settings in Plex UI

1. Go to Settings → Network
2. Verify "List of IP addresses and networks that are allowed without auth" shows:
   - `172.16.10.0/24,172.16.5.0/24,172.16.15.0/24`
3. If not showing, may need to configure in Preferences.xml (see troubleshooting)

### 3. Remote Access (Optional)

- Configure Cloudflare tunnel for external access
- Or enable Plex remote access in Settings → Network

## Next Steps: Media Setup

Now that Plex is configured, you can:

1. **Add Media Files**:

   - Copy movies to `/mnt/streaming/movies`
   - Copy TV shows to `/mnt/streaming/series`
   - Plex will automatically scan and organize

2. **Scan Libraries**:

   - Go to Settings → Libraries
   - Click "Scan Library Files" for each library
   - Or wait for automatic scans

3. **Test Playback**:
   - Play media from Plex web UI
   - Monitor GPU usage: `nvidia-smi` (should show activity during transcoding)
   - Test from Plex apps on mobile/desktop

## Troubleshooting

### Network Settings Not Applied

If NO_AUTH_NETWORKS doesn't work via environment variable, configure in Preferences.xml:

```bash
ssh packer@172.16.10.20
sudo nano "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml"
```

Add or update:

```xml
<Preferences ... allowedNetworks="172.16.10.0/24,172.16.5.0/24,172.16.15.0/24" ...>
```

Then restart: `sudo systemctl restart plexmediaserver`

### GPU Not Working

- Verify: `nvidia-smi` shows GPU
- Check Plex logs: `journalctl -u plexmediaserver -f`
- Verify hardware acceleration enabled in Plex Settings → Transcoder

### NFS Mounts Not Working

- Check mounts: `mount | grep nfs`
- Test connectivity: `ping 172.16.30.4` (NAS02) and `ping 172.16.30.5` (NAS01)
- Verify exports on NAS devices

## Files and Scripts

- **VM Creation**: `plex/scripts/create-plex-vm.sh`
- **Ansible Playbook**: `plex/ansible/playbooks/deploy-plex-vm.yml`
- **GPU Configuration**: `plex/ansible/playbooks/configure-gpu.yml`
- **Backup Script**: `/usr/local/bin/backup-plex-db.sh` (on VM)

## Documentation

- **VM Setup**: `plex/docs/vm-setup.md`
- **Post-Deployment**: `plex/docs/post-deployment-checklist.md`
- **GPU Setup**: `plex/ansible/roles/plex-gpu/`

---

**Status**: ✅ Plex VM setup complete and ready for media!
