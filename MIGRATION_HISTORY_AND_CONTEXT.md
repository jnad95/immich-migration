# 📖 Migration History & Architectural Context

This document captures the historical context, requirements, and design decisions of the Immich photo migration and storage project. If the environment ever needs to be rebuilt from scratch, this file serves as the core knowledge repository.

---

## 1. Project Goal & Origin
The project was initiated to consolidate disorganized photo libraries and data scattered across multiple devices and external hard drives onto a single, structured source of truth: a **Portable SSD** (mounted at `/Volumes/PortableSSD`).

### Storage Devices & History
*   **Samsung Tab S7**: Recovered and transferred files to a Mac Mini using **OpenMTP** (for wired transfer) and **NearDrop** (for wireless transfer).
*   **Basic Drive**: Audited, cleaned, and contents migrated to the Portable SSD.
*   **Seagate Drive**: Contains old backup versions, cleared and cleaned after merging files.
*   **Portable SSD**: The master storage drive.

---

## 2. Directory Layout & Organization
The Portable SSD is structured as follows:
*   `01_Personal/`: Personal files and documents.
*   `02_Professional/`: Career, code repositories, and work documents.
*   `03_Media/`: Media roots including:
    -   `immich-library/`: Local photo library managed by Immich.
    -   `immich-data/`: Database, redis, model caching, and ingest directories.
    -   `immich_manager_workspace/`: Docker compose configuration, `.env` file, logs, and shell scripts.
*   `04_Archive_Backups/`: Legacy backups, system backups, and device dumps.
*   `_Inbox/`: Entrypoint for new local files.

---

## 3. Local Strategy: Safe Deduplication
To manage duplicates without corrupting the active Immich library, two customized scripts were created:
1.  **[gatekeeper.sh](file:///Users/adityajain/gemini/gatekeeper.sh)**: Compares new files dropped in `_Inbox/` against safe paths (`01_Personal`, `02_Professional`, `04_Archive_Backups`) using `jdupes` to prevent ingest duplicates.
2.  **[run_dedupe.sh](file:///Users/adityajain/gemini/run_dedupe.sh)**: Safely runs deduplication audits across user-accessible SSD folders, strictly excluding the Immich system files to protect Postgres and active image database tables.

---

## 4. Pipeline Design: Drop Box & Backup
To bridge local SSD storage with cloud storage (Google Drive & OneDrive), a **Drop Box & Backup** flow was built:

### A. Ingestion
1.  Users drop photos in the cloud folder `Immich_DropBox/` (on OneDrive or GDrive).
2.  `ingest_to_immich.sh` runs via cron, checks that Immich is online, and uses `rclone move` to stage the files locally.
3.  The Immich CLI uploads files using the `--delete` flag (deleting only successfully uploaded local files).
4.  Any failed uploads are moved to `failed_uploads/YYYY-MM-DD_HH-MM-SS/` to prevent loss.

### B. Mirroring & Archiving
1.  `backup_immich.sh` mirrors local `/Volumes/PortableSSD/03_Media/immich-library/` to cloud folders under `Immich_Backup/` on GDrive and OneDrive.
2.  To prevent accidental local deletions from wiping out cloud backups, the script runs `rclone sync` with `--backup-dir`, placing deleted/modified files into an incremental archive (`Immich_Backup_Archive/YYYY-MM-DD/`).
3.  The script performs checks to ensure the library source is mounted and not empty before executing the sync.
