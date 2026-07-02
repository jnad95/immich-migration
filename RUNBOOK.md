# 📘 Runbook: Immich SSD & Cloud Data Pipeline Setup

This runbook guides you through setting up, configuring, and verifying the Immich photo/video database and cloud migration pipeline on your Portable SSD and Cloud Storages (Google Drive & OneDrive).

---

## 1. Prerequisites & Pre-Flight Safety (Zero Data Loss)
*   **Current State Check:** 
    1. Verify SSD is mounted at the expected path:
       ```bash
       ls -ld /Volumes/PortableSSD
       ```
    2. Confirm Docker Desktop is running and the command-line tools are available:
       ```bash
       docker --version && rclone --version
       ```
*   **Backup Protocol:** Always make a backup copy of your current workspace configuration files before making edits:
    ```bash
    cp -rp /Volumes/PortableSSD/03_Media/immich_manager_workspace /Users/adityajain/Desktop/immich_workspace_backup
    ```
*   **Backup Verification:** Confirm the backup folder exists and contains files matching the source:
    ```bash
    ls -l /Users/adityajain/Desktop/immich_workspace_backup
    ```

---

## 2. Sequential Execution Steps (Human-Replicable)

### Step 1: Configure Rclone Cloud Remotes
*   **Action/Command:** Execute rclone configure:
    ```bash
    rclone config --config /Volumes/PortableSSD/03_Media/immich_manager_workspace/rclone.conf
    ```
*   **Expected Outcome:** Launches the interactive menu:
    1. Select `n` for a new remote. Name it **`gdrive`**. Choose type `drive` (Google Drive). Follow the instructions for browser authentication.
    2. Select `n` for a second new remote. Name it **`onedrive`**. Choose type `onedrive`. Follow browser instructions for authentication.
    3. Quit the configurator when finished.

### Step 2: Create Staging Cloud Folders
*   **Action/Command:** Create the folders in both your Google Drive and OneDrive accounts:
    -   `Immich_DropBox` (Staging directory for incoming photos)
    -   `Immich_Backup` (Destination directory for media library mirroring)
    -   `Data_Backup` (Destination directory for personal/professional data mirroring)
*   **Expected Outcome:** Verify rclone can access them:
    ```bash
    rclone lsd gdrive: --config /Volumes/PortableSSD/03_Media/immich_manager_workspace/rclone.conf
    rclone lsd onedrive: --config /Volumes/PortableSSD/03_Media/immich_manager_workspace/rclone.conf
    ```

### Step 3: Start Docker Container Services
*   **Action/Command:** Change directories and launch the docker services:
    ```bash
    cd /Volumes/PortableSSD/03_Media/immich_manager_workspace && docker compose up -d
    ```
*   **Expected Outcome:** Check if services are running:
    ```bash
    docker compose ps
    ```
    All four services (`immich_server`, `immich_machine_learning`, `immich_redis`, `immich_postgres`) should show as running and healthy.

### Step 4: Schedule Automation via Cron
*   **Action/Command:** Edit system crontab scheduler:
    ```bash
    crontab -e
    ```
    Append these lines to the configuration file:
    ```text
    # Ingest from Cloud DropBox hourly
    0 * * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest_to_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest.log 2>&1

    # Backup to Cloud daily at 2:00 AM
    0 2 * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup.log 2>&1

    # Mirror & Deduplicate Personal/Professional/Archive files daily at 3:00 AM
    0 3 * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_data.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_data.log 2>&1
    ```
*   **Expected Outcome:** View configuration to check output:
    ```bash
    crontab -l
    ```
    All three cron jobs are listed correctly.

---

## 3. Validation & Checkpoints
1.  **Staging Test**: Drop a test photo/video file inside `Immich_DropBox` on Google Drive or OneDrive.
2.  **Ingest Run**: Execute the ingest script manually:
    ```bash
    /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest_to_immich.sh
    ```
3.  **Ingest Verification**:
    - Verify `ingest.log` matches execution.
    - Check that the test file was deleted from your cloud `Immich_DropBox` folder.
    - Log into `http://localhost:2283` and verify the photo displays on your timeline.
4.  **Backup Run**: Execute the backup script manually:
    ```bash
    /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_immich.sh
    ```
5.  **Backup Verification**:
    - Verify `backup.log` matches execution.
    - Check the remote cloud storage `Immich_Backup/` folder and ensure your SSD files successfully synced there.
6.  **Data Backup & Dedupe Run**: Run the non-media backup script:
    ```bash
    /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_data.sh
    ```
7.  **Data Backup Verification**:
    - Verify `backup_data.log` confirms successful execution and sync matching.
    - Verify `duplicates.log` for details on files cleaned by `jdupes`.
    - Check Google Drive and OneDrive folders under `Data_Backup/` to ensure your data mirrored.

---

## 4. Rollback & Recovery Plan
*   **Rollback Trigger:** Abort if cloud auth credentials cannot be set up, docker compose containers fail to start (Postgres unhealthy), or write errors block script execution.
*   **Recovery Steps:** 
    1. Spin down compose services and remove volumes:
       ```bash
       cd /Volumes/PortableSSD/03_Media/immich_manager_workspace && docker compose down -v
       ```
    2. Remove the modified workspace directory:
       ```bash
       rm -rf /Volumes/PortableSSD/03_Media/immich_manager_workspace
       ```
    3. Copy your pre-flight backup back onto the SSD:
       ```bash
       cp -rp /Users/adityajain/Desktop/immich_workspace_backup /Volumes/PortableSSD/03_Media/immich_manager_workspace
       ```
    4. Confirm backup restore:
       ```bash
       ls -la /Volumes/PortableSSD/03_Media/immich_manager_workspace
       ```
