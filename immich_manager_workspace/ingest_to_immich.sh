#!/bin/bash
# Ingest script for Immich - Source: Cloud DropBox
# Upgraded for robustness: checks instance health, SSD status, and prevents data loss.

set -o pipefail

WORKSPACE="/Volumes/PortableSSD/03_Media/immich_manager_workspace"
LOG_FILE="$WORKSPACE/ingest.log"

# Log helper function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Ingest Process Started ==="

# 1. Verify SSD Mount Point
SSD_PATH="/Volumes/PortableSSD"
if [ ! -d "$SSD_PATH" ]; then
    log "ERROR: SSD is not mounted at $SSD_PATH. Aborting ingest."
    exit 1
fi

# 2. Load environment variables
ENV_FILE="$WORKSPACE/.env"
if [ -f "$ENV_FILE" ]; then
    # Load variables excluding comments
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    log "ERROR: Environment file not found at $ENV_FILE. Aborting."
    exit 1
fi

if [ -z "$IMMICH_INSTANCE_URL" ] || [ -z "$IMMICH_API_KEY" ]; then
    log "ERROR: Missing Immich API configuration in .env. Aborting."
    exit 1
fi

# 3. Check if Immich Instance is Reachable
log "Checking connection to Immich instance at $IMMICH_INSTANCE_URL..."
if ! curl -s --connect-timeout 5 "$IMMICH_INSTANCE_URL/server-info/ping" >/dev/null; then
    # Retry once check
    log "WARNING: Immich ping failed. Checking main endpoint directly..."
    if ! curl -s --connect-timeout 5 "$IMMICH_INSTANCE_URL" >/dev/null; then
        log "ERROR: Immich server is unreachable. Aborting ingest to protect cloud inbox."
        exit 1
    fi
fi
log "Immich server is online."

# 4. Set up Temp and Failed directories
TEMP_DIR="/Volumes/PortableSSD/03_Media/immich-data/ingest_temp"
FAILED_DIR="$WORKSPACE/failed_uploads"
mkdir -p "$TEMP_DIR"

REMOTES=("gdrive:Immich_DropBox" "onedrive:Immich_DropBox")
RCLONE_CONF="$WORKSPACE/rclone.conf"

for REMOTE in "${REMOTES[@]}"; do
    log "Checking $REMOTE for new media..."
    
    # Check if remote config exists
    REMOTE_NAME=$(echo "$REMOTE" | cut -d':' -f1)
    if ! rclone listremotes --config "$RCLONE_CONF" 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        log "WARNING: Remote $REMOTE_NAME is not configured in rclone.conf. Skipping."
        continue
    fi

    # Move files to local temp directory
    log "Moving files from $REMOTE to local staging..."
    rclone move "$REMOTE" "$TEMP_DIR" \
        --include "*.{jpg,jpeg,png,mp4,mov,avi,HEIC,heic,JPG,JPEG,PNG,MP4,MOV,AVI}" \
        --config "$RCLONE_CONF" \
        --log-file="$WORKSPACE/rclone_ingest.log" \
        --log-level NOTICE
    
    # If files were moved successfully, process them
    if [ -d "$TEMP_DIR" ] && [ "$(ls -A "$TEMP_DIR")" ]; then
        log "Starting upload of staged files to Immich..."
        
        # Run Immich CLI upload.
        # Note: --delete will automatically delete files from $TEMP_DIR ONLY if successfully uploaded.
        immich upload \
            --key "$IMMICH_API_KEY" \
            --url "$IMMICH_INSTANCE_URL" \
            "$TEMP_DIR" \
            --recursive \
            --album \
            --delete \
            --delete-duplicates \
            --no-progress
        
        UPLOAD_STATUS=$?
        
        # Check if there are any remaining files that failed to upload
        if [ "$(ls -A "$TEMP_DIR")" ]; then
            TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
            FAILED_RUN_DIR="$FAILED_DIR/$TIMESTAMP"
            log "WARNING: Some files failed to upload. Preserving failed files in: $FAILED_RUN_DIR"
            mkdir -p "$FAILED_RUN_DIR"
            mv "$TEMP_DIR"/* "$FAILED_RUN_DIR/"
        else
            log "All files uploaded and cleaned up successfully for $REMOTE."
        fi
    else
        log "No new eligible files found in $REMOTE."
    fi
done

log "=== Ingest Process Completed ==="
