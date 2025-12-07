# Plex Watch History Sync Guide

## Overview

This document describes methods for syncing watch history from the old Plex server (NAS01 Docker) to the new Plex server (plex-vm-01).

## Methods

### Method 1: Plex Sync Feature (Recommended - Easiest)

Plex offers a built-in feature to sync watch state and ratings across servers.

#### Steps

1. **Enable on Old Server**:

   - Access old Plex server web UI
   - Go to Settings → Account
   - Enable "Sync Watch State and Ratings"

2. **Enable on New Server**:

   - Access new Plex server web UI (http://172.16.10.20:32400)
   - Go to Settings → Account
   - Enable "Sync Watch State and Ratings"

3. **Wait for Sync**:
   - Plex will automatically sync watch history for users who have this enabled
   - Sync happens in the background
   - May take some time depending on library size

#### Pros

- ✅ Built-in feature, no additional tools needed
- ✅ Automatic sync
- ✅ Works for all users who enable it

#### Cons

- ⚠️ Requires each user to enable the feature
- ⚠️ Only syncs for users who enable it
- ⚠️ May take time to complete

### Method 2: Database Migration (Advanced)

Directly migrate watch history from the old server's database to the new server.

#### Prerequisites

- Access to old Plex server database
- SQLite knowledge
- Both servers must be stopped during migration

#### Steps

1. **Backup Old Database**:

   ```bash
   # On old server (NAS01 Docker)
   docker exec plex cp "/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" /tmp/plex-db-backup.db
   ```

2. **Export Watch History**:

   ```bash
   # Extract watch history for specific users
   sqlite3 plex-db-backup.db "SELECT * FROM metadata_item_settings WHERE account_id IN (SELECT id FROM accounts WHERE name IN ('wife-username', 'your-username'));" > watch-history-export.sql
   ```

3. **Import to New Server**:

   ```bash
   # On new server
   # Stop Plex service
   sudo systemctl stop plexmediaserver

   # Backup new database
   sudo cp "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" /tmp/plex-db-new-backup.db

   # Import watch history (requires careful SQLite manipulation)
   # Note: This is complex and may require adjusting account IDs
   ```

#### Pros

- ✅ Complete control over what is migrated
- ✅ Can migrate specific users only

#### Cons

- ❌ Complex and error-prone
- ❌ Requires both servers to be offline
- ❌ Risk of database corruption if done incorrectly
- ❌ Account IDs may not match between servers

### Method 3: Third-Party Tools

Use tools like `plex-watched-sync` or `PlexTraktSync` to sync watch history.

#### PlexTraktSync

1. **Install PlexTraktSync**:

   ```bash
   pip install plextraktsync
   ```

2. **Configure**:

   ```bash
   plextraktsync login
   ```

3. **Sync**:

   ```bash
   # Sync from old server to Trakt
   plextraktsync sync --server old-plex-server

   # Sync from Trakt to new server
   plextraktsync sync --server new-plex-server
   ```

#### Pros

- ✅ Can sync via intermediate service (Trakt.tv)
- ✅ Works even if old server is offline later

#### Cons

- ⚠️ Requires Trakt.tv account
- ⚠️ Additional dependency

## Recommendation

**For your use case** (wife's watch history, optionally yours):

1. **Start with Method 1** (Plex Sync Feature):

   - Easiest and safest
   - Have your wife enable it on her account
   - Enable it on your account if desired
   - Let it sync automatically

2. **If Method 1 doesn't work or misses data**:

   - Use Method 3 (PlexTraktSync) as backup
   - Set up Trakt.tv accounts
   - Sync via Trakt as intermediary

3. **Avoid Method 2** unless absolutely necessary:
   - Too complex and risky
   - Only use if other methods fail

## Implementation Timeline

- **Phase 1**: Set up new Plex server (current)
- **Phase 2**: Configure and test new server
- **Phase 3**: Enable Plex Sync Feature on both servers
- **Phase 4**: Monitor sync progress
- **Phase 5**: Decommission old server (after sync verified)

## Notes

- Watch history sync is **not critical** - can be done later
- Both servers can run simultaneously during sync
- Old server will remain available until sync is complete
