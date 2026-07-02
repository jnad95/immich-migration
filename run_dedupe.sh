#!/bin/bash
DIRS=("/Volumes/PortableSSD/01_Personal" "/Volumes/PortableSSD/02_Professional" "/Volumes/PortableSSD/04_Archive_Backups")
for d in /Volumes/PortableSSD/03_Media/*/; do
  if [[ "$d" != *"immich"* ]]; then
    DIRS+=("$d")
  fi
done
if [ -d "/Volumes/PortableSSD/00_Inbox" ]; then
    DIRS+=("/Volumes/PortableSSD/00_Inbox")
fi
if [ -d "/Volumes/PortableSSD/_Inbox" ]; then
    DIRS+=("/Volumes/PortableSSD/_Inbox")
fi

echo "Starting deduplication. Excluded Immich folders."
echo "Priority order (first preserved, rest deleted):"
printf '  %s\n' "${DIRS[@]}"

jdupes -r -O -d -N "${DIRS[@]}" > /Users/adityajain/gemini/final_duplicates_report.txt
echo "Deduplication complete."
