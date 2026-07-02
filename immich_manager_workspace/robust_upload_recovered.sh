#!/bin/bash
export IMMICH_INSTANCE_URL="http://localhost:2283/api"
export IMMICH_API_KEY="izzrJtT9nb5UkUds1x6B7gTuAvC9z6243pHdCT7OEYI"

MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Starting upload for recovered files (Attempt $(($RETRY_COUNT+1)))..."
    # No --album flag since the original folders are lost, just get them back into the timeline
    immich upload /Volumes/PortableSSD/04_Archive_Backups/samsung_recovered -r --delete --delete-duplicates --no-progress -c 3
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Upload completed successfully."
        exit 0
    else
        echo "Upload failed with exit code $EXIT_CODE. Retrying in 5 seconds..."
        sleep 5
        RETRY_COUNT=$(($RETRY_COUNT+1))
    fi
done

echo "Max retries reached. Upload failed."
exit 1
