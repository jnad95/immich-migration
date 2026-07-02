#!/bin/bash
# Backup & Deduplication Script for Non-Media Data
# Mirrors Personal, Professional, and Archive backups to GDrive and OneDrive.
# Automatically resolves duplicates locally on the SSD before starting the sync.

set -o pipefail

WORKSPACE="/Volumes/PortableSSD/03_Media/immich_manager_workspace"
LOG_FILE="$WORKSPACE/backup_data.log"
RCLONE_CONF="$WORKSPACE/rclone.conf"
TIMESTAMP=$(date '+%Y-%m-%d')

# Log helper function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Non-Media Data Backup & Dedupe Process Started ==="

# 1. Verify SSD Mount Point
SSD_PATH="/Volumes/PortableSSD"
if [ ! -d "$SSD_PATH" ]; then
    log "ERROR: SSD is not mounted at $SSD_PATH. Aborting pipeline."
    exit 1
fi

# Define source directories (Ordered by retention priority: Personal first, then Professional, then Archive)
SOURCES=(
    "/Volumes/PortableSSD/01_Personal"
    "/Volumes/PortableSSD/02_Professional"
    "/Volumes/PortableSSD/04_Archive_Backups"
)

# 2. Check each source directory
for SRC in "${SOURCES[@]}"; do
    if [ ! -d "$SRC" ]; then
        log "ERROR: Source directory $SRC does not exist. Aborting pipeline to prevent cloud deletion."
        exit 1
    fi
    if [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
        log "ERROR: Source directory $SRC is empty. Aborting pipeline to prevent cloud deletion."
        exit 1
    fi
done

# 3. Execute Local Deduplication Check
log "Running local deduplication check using jdupes..."
log "Priority order (first preserved, rest deleted): ${SOURCES[*]}"

# Run jdupes automatically (-N for noprompt / auto-delete, -O for parameter order priority)
jdupes -r -O -d -N "${SOURCES[@]}" > "$WORKSPACE/duplicates.log" 2>&1
jdupes_status=$?

if [ $jdupes_status -eq 0 ] || [ $jdupes_status -eq 1 ]; then
    log "Local deduplication complete. Checked duplicates log stored in: $WORKSPACE/duplicates.log"
else
    log "WARNING: jdupes exited with code $jdupes_status. Proceeding to sync phase."
fi

# 4. Sync Clean Folders to Cloud Remotes
REMOTES=("gdrive:Data_Backup" "onedrive:Data_Backup")

for REMOTE in "${REMOTES[@]}"; do
    REMOTE_NAME=$(echo "$REMOTE" | cut -d':' -f1)
    
    # Check if remote config exists in rclone.conf
    if ! rclone listremotes --config "$RCLONE_CONF" 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        log "WARNING: Remote $REMOTE_NAME is not configured in rclone.conf. Skipping backup for this remote."
        continue
    fi

    log "Starting sync to $REMOTE..."
    
    for SRC in "${SOURCES[@]}"; do
        FOLDER_NAME=$(basename "$SRC")
        DEST_PATH="$REMOTE/$FOLDER_NAME"
        BACKUP_DIR="${REMOTE_NAME}:Data_Backup_Archive/$TIMESTAMP/$FOLDER_NAME"
        
        log "Syncing $FOLDER_NAME to $DEST_PATH (Archive changes to: $BACKUP_DIR)"
        
        rclone sync "$SRC" "$DEST_PATH" \
            --backup-dir "$BACKUP_DIR" \
            --transfers 4 \
            --checkers 8 \
            --config "$RCLONE_CONF" \
            --log-file="$WORKSPACE/rclone_data_backup.log" \
            --log-level NOTICE
        
        sync_status=$?
        if [ $sync_status -eq 0 ]; then
            log "Successfully synchronized $FOLDER_NAME to $DEST_PATH."
        else
            log "ERROR: Failed to sync $FOLDER_NAME to $DEST_PATH. Exit code: $sync_status"
        fi
    done
done

log "=== Non-Media Data Backup & Dedupe Process Completed ==="
