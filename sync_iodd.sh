#!/bin/bash

# CONFIGURATION
SOURCE_SERVER="user@main-server:/sync-repo"   # The master repository
IODD_MOUNT="/mnt/iodd"                        # The mounted IODD path
BACKUP_DIR="$IODD_MOUNT/backup"               # Backup directory for conflicts
EXCLUDE_FILE="/tmp/exclude_list.txt"          # File containing user exclusions
LOG_FILE="/mnt/logs/iodd-sync.log"            # Sync log file

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ensure IODD is mounted
if [ ! -d "$IODD_MOUNT" ]; then
    log "❌ Error: IODD drive is not detected at $IODD_MOUNT. Exiting."
    exit 1
fi

# Display sync options to the IT tech
clear
log "🔄 IODD Sync Tool - IT Workshop"
echo "Please choose a sync option:"
echo "1) 🛠 Test Sync (Dry Run - No changes, only check errors)"
echo "2) 🔄 Full Sync (Overwrite IODD with latest from main server)"
echo "3) 🛠 Selective Sync (Choose what to update)"
echo "4) 🔁 Sync New Files Only (Copies new files from IODD -> Server)"
echo "5) 🔍 Keep Specific Files/Folders & Sync Everything Else"
echo "6) 🚪 Exit"

read -p "Enter your choice [1-6]: " choice

# Function to let the user exclude files/folders from sync
select_exclusions() {
    log "🔍 Select files or folders to keep (exclude from sync)."
    rsync -avz --dry-run --progress "$SOURCE_SERVER/" "$IODD_MOUNT/" | grep '^d' | awk '{print $NF}' > /tmp/sync_list.txt
    cat /tmp/sync_list.txt

    read -p "Enter file(s) or folder(s) to exclude (comma-separated): " exclude_input
    echo "$exclude_input" | tr ',' '\n' > "$EXCLUDE_FILE"
    log "✅ Selected exclusions: $(cat $EXCLUDE_FILE)"
}

# Test Sync Mode - Dry run, check for errors before actual sync
sync_test() {
    log "🛠 Running Test Sync (Dry Run)..."
    rsync -avz --dry-run --progress "$SOURCE_SERVER/" "$IODD_MOUNT/" 2>&1 | tee -a "$LOG_FILE"
    
    # Check for rsync errors
    if grep -q "rsync error" "$LOG_FILE"; then
        log "⚠ Rsync encountered errors. Please check the log and resolve them before running a full sync."
        exit 1
    else
        log "✅ Test Sync completed with no errors."
    fi
}

# Full Sync - Overwrites IODD with the latest version from the main server
sync_full() {
    log "🔄 Performing Full Sync..."
    rsync -avz --progress --delete "$SOURCE_SERVER/" "$IODD_MOUNT/"
    log "✅ Full Sync Completed!"
}

# Selective Sync - Prompts for specific directories/files to sync
sync_selective() {
    log "🛠 Performing Selective Sync..."
    rsync -avz --progress --delete --ignore-existing "$SOURCE_SERVER/" "$IODD_MOUNT/" --dry-run | grep '^d' | awk '{print $NF}' > /tmp/sync_list.txt
    cat /tmp/sync_list.txt

    read -p "Enter directory or file to sync (exact match required): " selection
    if [ -n "$selection" ]; then
        rsync -avz --progress --delete "$SOURCE_SERVER/$selection" "$IODD_MOUNT/$selection"
        log "✅ Selected item '$selection' synced successfully."
    else
        log "⚠ No selection made. Exiting selective sync."
    fi
}

# New Files Only Sync - Copies new files from IODD to Server
sync_new_files() {
    log "🔁 Syncing new files from IODD to the main server..."
    rsync -avz --progress --ignore-existing "$IODD_MOUNT/" "$SOURCE_SERVER/"
    log "✅ New files sync completed!"
}

# Keep Specific Files/Folders & Sync Everything Else
sync_keep_files() {
    select_exclusions  # Let the user choose files/folders to keep
    log "🔄 Syncing everything except exclusions..."
    rsync -avz --progress --delete --exclude-from="$EXCLUDE_FILE" "$SOURCE_SERVER/" "$IODD_MOUNT/"
    log "✅ Sync completed while keeping exclusions!"
}

# Handle user selection
case "$choice" in
    1) sync_test ;;
    2) sync_full ;;
    3) sync_selective ;;
    4) sync_new_files ;;
    5) sync_keep_files ;;
    6) log "🚪 Exiting script. No sync performed." && exit 0 ;;
    *) log "⚠ Invalid choice. Exiting." && exit 1 ;;
esac
