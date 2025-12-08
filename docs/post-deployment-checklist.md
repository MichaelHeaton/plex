# Plex VM Post-Deployment Checklist

## Overview

This checklist covers the manual steps required after the Ansible playbook has been run to complete the Plex VM setup.

## Prerequisites

- ✅ VM created and running
- ✅ Ansible playbook executed successfully
- ✅ Plex Media Server installed and running
- ✅ NFS mounts configured and accessible
- ✅ Network configured (static IP: 172.16.10.20)

## Manual Configuration Steps

### 1. Access Plex Web UI

- **URL**: `http://172.16.10.20:32400`
- **Initial Setup**: First-time setup wizard should appear
- **Note**: If you see "Server Unclaimed", proceed to claim the server

### 2. Claim Plex Server

1. Go to [Plex.tv/claim](https://www.plex.tv/claim/)
2. Get your claim token (valid for 4 minutes)
3. In Plex web UI, go to Settings → General
4. Enter the claim token in "Claim Server" field
5. Click "Claim Server"

**Alternative**: Use environment variable `PLEX_CLAIM_TOKEN` in `/etc/default/plexmediaserver` and restart service

### 3. Add Media Libraries

1. Go to Settings → Libraries
2. Click "Add Library"
3. Add libraries:
   - **Movies**: `/mnt/streaming/movies`
   - **TV Shows**: `/mnt/streaming/series`
4. Configure library settings:
   - Scanner: Plex Movie Scanner (for movies) / Plex TV Series Scanner (for TV)
   - Agent: Plex Movie / TheTVDB
   - Enable "Use local assets" if desired

### 4. Configure Network Settings

1. Go to Settings → Network
2. Configure:
   - **PLEX_NO_AUTH_NETWORKS**: `172.16.10.0/24,172.16.5.0/24` (VLAN 10 and VLAN 5)
   - **Secure connections**: Preferred (or Required for remote)
   - **Remote access**: Configure as needed (or use Cloudflare tunnel later)

### 5. Configure Transcoding

1. Go to Settings → Transcoder
2. Configure:
   - **Transcoder temporary directory**: `/mnt/streaming/transcoding`
   - **Enable hardware acceleration**: Yes (if GPU passthrough is working)
   - **Hardware transcoding device**: NVIDIA (if GPU detected)
   - **Maximum simultaneous video transcode sessions**: 4 (adjust based on GPU)

### 6. Verify GPU Passthrough (If Configured)

1. **In VM**, check GPU detection:

   ```bash
   ssh packer@172.16.10.20
   nvidia-smi
   ```

2. **If GPU not detected**:

   - Install NVIDIA drivers in VM
   - Verify Proxmox GPU passthrough configuration
   - Check IOMMU is enabled on Proxmox host

3. **In Plex**, verify hardware transcoding:
   - Go to Settings → Transcoder
   - Check "Hardware acceleration" is enabled
   - Test transcoding with a video

### 7. Configure Remote Access (Optional - Cloudflare Tunnel)

1. **Set up Cloudflare Tunnel** (future task):

   - Install cloudflared on VM or Proxmox host
   - Configure tunnel to route `streaming.specterrealm.com` → `172.16.10.20:32400`
   - Update DNS records in Cloudflare

2. **Or use Plex Relay** (temporary):
   - Enable remote access in Plex settings
   - Plex will use relay service for external access

### 8. Test Media Playback

1. **Add test media** to `/mnt/streaming/movies` or `/mnt/streaming/series`
2. **Scan libraries** in Plex (Settings → Libraries → Scan Library Files)
3. **Test playback** from Plex web UI
4. **Test from Plex app** on mobile/desktop
5. **Monitor transcoding** (if applicable):
   - Check transcoding directory: `ls -lh /mnt/streaming/transcoding/`
   - Monitor GPU usage: `nvidia-smi` (if GPU passthrough)

### 9. Configure Backup Verification

1. **Check backup timer**:

   ```bash
   ssh packer@172.16.10.20
   systemctl status plex-backup.timer
   ```

2. **Test backup manually**:

   ```bash
   sudo /usr/local/bin/backup-plex-db.sh
   ```

3. **Verify backup created**:
   ```bash
   ls -lh /mnt/backups/databases/plex/
   ```

### 10. Update DNS Records (UniFi)

1. **Add DNS record** in UniFi Controller:

   - **Name**: `plex-vm-01`
   - **Type**: A
   - **IP**: `172.16.10.20`
   - **Domain**: `specterrealm.com`

2. **Verify DNS resolution**:
   ```bash
   nslookup plex-vm-01.specterrealm.com
   ```

### 11. Configure Traefik Routing ✅

**Status**: ✅ Complete

**Traefik routing is now configured**:

1. ✅ Traefik route added: `streaming.specterrealm.com` → `172.16.10.20:32400`
2. ✅ SSL certificate configured (Let's Encrypt via Cloudflare DNS challenge)
3. ✅ DNS record added: `streaming.specterrealm.com` (CNAME to `traefik.specterrealm.com`)
4. ✅ Accessible at: `https://streaming.specterrealm.com`

**Configuration Details**:

- Route configured in `docker-swarm/stacks/dynamic/traefik-routers.yml`
- Service: `plex` (file provider, points to Plex VM)
- Backend: `http://172.16.10.20:32400`
- SSL: Automatic via Let's Encrypt
- Access: LAN only (172.16.0.0/12, 10.0.0.0/8)

## Verification Checklist

- [ ] Plex web UI accessible at `http://172.16.10.20:32400`
- [ ] Server claimed with Plex account
- [ ] Media libraries added and scanning
- [ ] Network settings configured (local auth networks)
- [ ] Transcoding configured (hardware acceleration if GPU available)
- [ ] GPU passthrough working (if configured) - `nvidia-smi` shows GPU
- [ ] Media playback working
- [ ] Backup automation running (check timer status)
- [x] DNS record added for `plex-vm-01.specterrealm.com`
- [x] DNS record added for `streaming.specterrealm.com` (CNAME to Traefik)
- [x] Traefik route configured for `streaming.specterrealm.com`
- [ ] Firewall allows Plex port (32400)

## Next Steps

1. **Watch History Sync** (Optional - see `watch-history-sync.md`):

   - Enable Plex Sync Feature on both old and new servers
   - Monitor sync progress

2. **Switch Clients**:

   - Update Plex app settings to use new server
   - Test from all client devices

3. **Decommission Old Server** (After verification):

   - Stop old Plex container on NAS01
   - Remove Docker Compose configuration (optional)

4. **Traefik Integration** ✅ Complete:
   - ✅ Traefik route configured
   - ✅ SSL certificate set up (Let's Encrypt)
   - ✅ Accessible at `https://streaming.specterrealm.com`

## Troubleshooting

### Plex Web UI Not Accessible

- Check VM is running: `qm status 102` on Proxmox host
- Check Plex service: `systemctl status plexmediaserver` in VM
- Check firewall: `sudo ufw status` in VM
- Check network: `ip addr show` in VM

### NFS Mounts Not Working

- Verify shares exist on NAS02
- Check NAS02 NFS export permissions
- Test connectivity: `ping 172.16.30.4` from VM
- Check mounts: `mount | grep nfs` in VM

### GPU Not Detected

- Verify GPU passthrough in Proxmox: `qm config 102 | grep hostpci`
- Check IOMMU enabled on Proxmox host
- Install NVIDIA drivers in VM
- Verify with `nvidia-smi`
