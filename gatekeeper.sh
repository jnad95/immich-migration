#!/bin/bash

# Gatekeeper: A script to prevent duplicates when adding new data to PortableSSD

DEST="/Volumes/PortableSSD"
INBOX="$DEST/_Inbox"
JDUPES="/opt/homebrew/bin/jdupes"

if [ ! -d "$INBOX" ]; then
    mkdir -p "$INBOX"
    echo "Created $INBOX. Please put new files there."
    exit 0
fi

# Check for files in Inbox
if [ "$(ls -A $INBOX)" ]; then
    echo "Checking for duplicates in Inbox..."
    # Compare Inbox with the rest of the drive, explicitly excluding Immich directories
    # to avoid corrupting its internal database or touching managed library files.
    # We do this by feeding specific safe top-level directories to jdupes instead of the whole DEST.
    SAFE_DIRS=("$DEST/01_Personal" "$DEST/02_Professional" "$DEST/04_Archive_Backups")
    EXISTING_DIRS=()
    for d in "${SAFE_DIRS[@]}"; do
        if [ -d "$d" ]; then
            EXISTING_DIRS+=("$d")
        fi
    done
    
    if [ ${#EXISTING_DIRS[@]} -gt 0 ]; then
        $JDUPES -r "$INBOX" "${EXISTING_DIRS[@]}"
    else
        echo "No safe destination directories found to compare against."
    fi
    
    echo "--------------------------------"
    echo "Review the list above. If an Inbox file matches an existing file, delete it from Inbox."
else
    echo "Inbox is empty."
fi
