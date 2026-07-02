# 📝 Outstanding User Setup Tasks

These tasks are required to finalize the photo management system. Once completed, this file can be updated or deleted.

## 1. Cloud Authentication (Rclone)
The automation scripts need access to your Google Drive and OneDrive.
- [ ] Run the following command:
  ```bash
  rclone config --config /Volumes/PortableSSD/03_Media/immich_manager_workspace/rclone.conf
  ```
- [ ] Create a remote named **`gdrive`** (Google Drive).
- [ ] Create a remote named **`onedrive`** (OneDrive).
- [ ] Ensure you create the following folders in your cloud accounts:
    - `Immich_DropBox` (For dropping new photos to be ingested)
    - `Immich_Backup` (Where the SSD library will be mirrored)

## 2. Schedule Automation (Cron)
To make the "Drop Box" and "Backup" logic work automatically, add these to your system scheduler.
- [ ] Run `crontab -e` and add:
  ```bash
  # Ingest every hour
  0 * * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest_to_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest.log 2>&1
  # Backup every night at 2 AM
  0 2 * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup.log 2>&1
  ```

## 3. Monitor Migration
The bulk upload is currently running in the background on the SSD.
- [ ] Check progress by reading the logs:
  ```bash
  tail -f /Volumes/PortableSSD/03_Media/immich_manager_workspace/upload_samsung.log
  ```
- [ ] Once the logs show "Successfully uploaded" for all files, you can delete the empty source folders:
    - `/Volumes/PortableSSD/04_Archive_Backups/samsung/`
    - `/Volumes/PortableSSD/03_Media/Media/`

---
*Note: This file is referenced in LLM_CONTEXT.md so any AI assistant can help you with these steps later.*
