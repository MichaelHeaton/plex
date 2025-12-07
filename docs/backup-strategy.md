# Plex Backup Strategy

## Overview

This document describes the backup strategy for the Plex Media Server VM, including database backups, configuration backups, and recovery procedures.

## Backup Components

### 1. Plex Database Backup

**Location**: `/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/`

**What's Backed Up**:

- Database files (metadata, watch history, settings)
- Preferences and server configuration
- User accounts and permissions
- Library metadata

**What's NOT Backed Up**:

- Cache files (regenerated automatically)
- Codecs (downloaded as needed)
- Logs (rotated automatically)
- Crash reports

**Backup Location**: `/mnt/backups/databases/plex/`

**Automation**: Systemd timer runs daily with randomized delay

**Retention**: 14 days

### 2. Configuration Backup

**Plex Configuration Files**:

- `/etc/default/plexmediaserver` - Environment configuration
- `/var/lib/plexmediaserver/Preferences.xml` - Server preferences

**VM Configuration**:

- Network configuration (`/etc/netplan/`)
- Firewall rules (`/etc/ufw/`)
- NFS mount configuration (`/etc/fstab`)

**Backup Method**: Ansible playbooks (version controlled in git)

## Backup Automation

### Systemd Timer

**Service**: `plex-backup.service`
**Timer**: `plex-backup.timer`
**Schedule**: Daily with 1-hour randomized delay

**Script**: `/usr/local/bin/backup-plex-db.sh`

### Manual Backup

```bash
# Run backup manually
sudo /usr/local/bin/backup-plex-db.sh

# Check backup status
systemctl status plex-backup.timer
journalctl -u plex-backup.service -f
```

## Recovery Procedures

### Restore Plex Database

1. **Stop Plex Service**:

   ```bash
   sudo systemctl stop plexmediaserver
   ```

2. **Backup Current Database**:

   ```bash
   sudo cp "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" /tmp/current-db-backup.db
   ```

3. **Restore from Backup**:

   ```bash
   # List available backups
   ls -lh /mnt/backups/databases/plex/

   # Extract backup
   tar -xzf /mnt/backups/databases/plex/plex-db-backup-YYYYMMDD-HHMMSS.tar.gz -C /tmp/

   # Restore database (be careful - this will overwrite current database)
   sudo cp /tmp/.../com.plexapp.plugins.library.db "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/"
   sudo chown plex:plex "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
   ```

4. **Start Plex Service**:
   ```bash
   sudo systemctl start plexmediaserver
   ```

### Full VM Recovery

If the entire VM needs to be recovered:

1. **Restore VM from Proxmox Backup** (if available)
2. **Re-run Ansible playbooks** to restore configuration
3. **Restore Plex database** from backup

## Backup Verification

### Check Backup Status

```bash
# List backups
ls -lh /mnt/backups/databases/plex/

# Check backup integrity
tar -tzf /mnt/backups/databases/plex/plex-db-backup-*.tar.gz | head

# Verify backup age
find /mnt/backups/databases/plex/ -name "*.tar.gz" -mtime -1
```

### Test Restore

Periodically test database restore in a test environment to ensure backups are valid.

## Backup Storage

- **Location**: `/mnt/backups/databases/plex/` (NFS mount from NAS02)
- **Network Access**: Via Proxmox host routing (VLAN 10 → VLAN 30) - VM does not have direct VLAN 30 access
- **Redundancy**: NAS02 provides storage redundancy
- **Offsite Backup**: Consider backing up to external storage or cloud (future enhancement)

## Monitoring

### Check Backup Timer Status

```bash
systemctl status plex-backup.timer
systemctl list-timers | grep plex-backup
```

### Check Backup Logs

```bash
journalctl -u plex-backup.service -f
journalctl -u plex-backup.service --since "1 day ago"
```

## Notes

- Backups are stored on NFS share, so they persist even if VM is lost
- Database backups are compressed (tar.gz) to save space
- Retention policy keeps last 14 days (adjustable in backup script)
- Media files are not backed up (stored on `/mnt/streaming` which is on NAS02)
