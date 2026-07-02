# Immich Manager - LLM Context Document

## Overview
This workspace manages an Immich instance hosted on a Portable SSD. It uses a "Drop Box & Backup" strategy to integrate with Google Drive and OneDrive while keeping the SSD as the source of truth.

## 📝 Pending User Tasks
See [USER_TASKS_TODO.md](./USER_TASKS_TODO.md) for required manual setup steps (Rclone config, Cron scheduling).

## Directory Structure
- **Workspace:** `/Volumes/PortableSSD/03_Media/immich_manager_workspace` (Docker configs, scripts, logs, rclone.conf)
- **Media Library:** `/Volumes/PortableSSD/03_Media/immich-library` (Managed by Immich)
- **Data/DB Storage:** `/Volumes/PortableSSD/03_Media/immich-data` (Postgres, Redis, ML models)

## Architecture: Drop Box & Backup
1. **Ingest Flow:** Cloud DropBox (`Immich_DropBox` folder) -> `ingest_to_immich.sh` (rclone move) -> Immich Upload -> Local & Cloud Cleanup.
2. **Backup Flow:** `immich-library` -> `backup_immich.sh` (rclone sync) -> Cloud Backup Folder (`Immich_Backup`).

## Automation
- **Ingest Script:** `./ingest_to_immich.sh` (Call via cron)
- **Backup Script:** `./backup_immich.sh` (Call via cron)

## Components
- **Immich:** Photo/Video management server (Docker).
- **Rclone:** Sync engine for cloud connectivity. Config stored in `rclone.conf` in this workspace.
- **Immich CLI:** Used for automated ingestion and bulk migration.

## Current State
- [x] Docker Infrastructure (SSD-mapped)
- [ ] Rclone Configuration (Pending User Auth)
- [x] Ingest Scripts (Ready)
- [x] Backup Scripts (Ready)
- [x] Initial Migration (Resumed in background)

## Platform Independence
To move to another machine:
1. Connect SSD.
2. Ensure Docker and Rclone are installed.
3. Run `docker compose up -d` in this folder.
4. Update cron jobs on the new host machine.

## Troubleshooting
- **Postgres Unhealthy:** Check for `._*` files on the SSD using `dot_clean /Volumes/PortableSSD/03_Media/immich-data`.
- **Docker Crash:** Restart Docker Desktop. Massive hashing operations during initial migration can strain the Docker daemon.
