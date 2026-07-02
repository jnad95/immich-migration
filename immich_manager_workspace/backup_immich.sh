#!/bin/bash
# Backup script for Immich - Source: SSD Library
# Upgraded for robustness: checks source availability, validates content, and archiving deletions.

set -o pipefail

WORKSPACE="/Volumes/PortableSSD/03_Media/immich_manager_workspace"
LOG_FILE="$WORKSPACE/backup.log"

# Log helper function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Backup Process Started ==="

# 1. Verify SSD Mount Point
SSD_PATH="/Volumes/PortableSSD"
if [ ! -d "$SSD_PATH" ]; then
    log "ERROR: SSD is not mounted at $SSD_PATH. Aborting backup."
    exit 1
fi

SOURCE="/Volumes/PortableSSD/03_Media/immich-library"
RCLONE_CONF="$WORKSPACE/rclone.conf"

# 2. Check if Source Directory Exists and is NOT Empty
if [ ! -d "$SOURCE" ]; then
    log "ERROR: Source directory $SOURCE does not exist. Aborting backup to prevent remote deletion."
    exit 1
fi

if [ -z "$(ls -A "$SOURCE" 2>/dev/null)" ]; then
    log "ERROR: Source directory $SOURCE is empty. Aborting backup to prevent remote deletion."
    exit 1
fi

# 3. Rclone remotes configuration
REMOTES=("gdrive:Immich_Backup" "onedrive:Immich_Backup")
TIMESTAMP=$(date '+%Y-%m-%d')

for REMOTE in "${REMOTES[@]}"; do
    log "Backing up to $REMOTE..."
    
    # Check if remote config exists
    REMOTE_NAME=$(echo "$REMOTE" | cut -d':' -f1)
    if ! rclone listremotes --config "$RCLONE_CONF" 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        log "WARNING: Remote $REMOTE_NAME is not configured in rclone.conf. Skipping backup for this remote."
        continue
    fi

    # Set up backup directory on remote to archive deleted or modified files
    BACKUP_DIR="${REMOTE_NAME}:Immich_Backup_Archive/$TIMESTAMP"
    log "Archiving deletions/modifications to $BACKUP_DIR"

    # Execute sync with safety measures
    rclone sync "$SOURCE" "$REMOTE" \
        --backup-dir "$BACKUP_DIR" \
        --transfers 4 \
        --checkers 8 \
        --config "$RCLONE_CONF" \
        --log-file="$WORKSPACE/rclone_backup.log" \
        --log-level NOTICE
    
    SYNC_STATUS=$?
    if [ $SYNC_STATUS -eq 0 ]; then
        log "Successfully synchronized $SOURCE to $REMOTE."
    else
        log "ERROR: Failed to sync $SOURCE to $REMOTE. Exit code: $SYNC_STATUS"
    fi
done

log "=== Backup Process Completed ==="
