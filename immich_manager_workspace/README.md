# Immich SSD & Cloud Data Pipeline

This workspace manages a self-hosted Immich photo/video library on a Portable SSD, integrated with Google Drive and OneDrive using a **Drop Box & Backup** strategy.

---

## 📂 Directory Layout

```text
/Volumes/PortableSSD/
├── 01_Personal/               # Personal documents & files
├── 02_Professional/           # Work & projects
├── 03_Media/                  # Media library root
│   ├── immich-library/        # Managed Immich photo/video library (Source of Truth)
│   ├── immich-data/           # Database, Valkey, machine learning model cache
│   └── immich_manager_workspace/  # THIS DIRECTORY: Docker, automation scripts, and logs
│       ├── failed_uploads/    # Timestamped directories containing failed uploads
│       ├── backup_immich.sh   # Cloud backup sync script
│       ├── ingest_to_immich.sh# Cloud inbox ingestion script
│       └── docker-compose.yml # Immich Docker services definition
└── _Inbox/                    # Local inbox staging folder
```

---

## ⚙️ Setup & Configuration

### 1. Start the Docker Stack
Make sure Docker Desktop is running on your Mac, then start Immich:
```bash
cd /Volumes/PortableSSD/03_Media/immich_manager_workspace
docker compose up -d
```
Immich will be accessible at: **`http://localhost:2283`**

### 2. Configure Cloud Connections (Rclone)
Run the configuration utility:
```bash
rclone config --config /Volumes/PortableSSD/03_Media/immich_manager_workspace/rclone.conf
```
Configure two remotes:
1.  **`gdrive`** (Google Drive)
2.  **`onedrive`** (OneDrive)

Create these folders inside both cloud storage accounts:
-   `Immich_DropBox` (Staging directory for upload/ingestion)
-   `Immich_Backup` (Mirrored backup folder)

### 3. Automate Ingest and Backups (Cron)
Add automation cron jobs to your system scheduler. Run `crontab -e` and add the following lines:
```bash
# Ingest from Cloud DropBox hourly
0 * * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest_to_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/ingest.log 2>&1

# Mirror Immich Library to Cloud daily at 2:00 AM
0 2 * * * /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup_immich.sh >> /Volumes/PortableSSD/03_Media/immich_manager_workspace/backup.log 2>&1
```

---

## 🛠️ Automated Scripts Operations

### A. Ingestion: `ingest_to_immich.sh`
-   **What it does**: Checks if Immich is online and reachable. Pulls new media from `gdrive:Immich_DropBox` and `onedrive:Immich_DropBox` into staging, uploads them to Immich using the Immich CLI, and handles cleanup.
-   **Data Safety**: Uses a zero-data-loss flow. Files are only deleted if they are successfully uploaded.
-   **Failed Uploads**: Any files that fail to upload are moved to `failed_uploads/YYYY-MM-DD_HH-MM-SS/` for manual inspection rather than being deleted. Check this folder if something doesn't show up in your Immich library.

### B. Mirror Backup: `backup_immich.sh`
-   **What it does**: Mirrors the local `immich-library` folder to the cloud under `Immich_Backup/`.
-   **Data Safety**: Checks if the source SSD directory is mounted and has files before starting. It will abort if the directory is missing or empty, protecting your cloud backups from being wiped out.
-   **Incremental Archiving**: Employs `--backup-dir` configuration. Deleted or modified files are moved to `Immich_Backup_Archive/YYYY-MM-DD/` on the cloud remote instead of being deleted permanently.

---

## 📝 Logging & Monitoring

Logs are saved in this workspace directory:
-   `ingest.log`: Main ingestion pipeline steps and validation checks.
-   `backup.log`: Mirror backup task execution logs.
-   `rclone_ingest.log` & `rclone_backup.log`: Detailed rclone command outputs.
