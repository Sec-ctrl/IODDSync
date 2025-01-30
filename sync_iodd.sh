#!/bin/bash

# CONFIGURATION
SOURCE_SERVER="user@main-server:/sync-repo"   # The master repository
IODD_MOUNT="/mnt/iodd"                        # The mounted IODD path (will be auto-checked)
EXCLUDE_FILE="/tmp/exclude_list.txt"          # File containing user exclusions
LOG_FILE="/var/log/iodd-sync.log"             # Sync log file

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Detect IODD Mount Automatically
detect_iodd() {
    IODD_MOUNT=$(findmnt -rn -S LABEL=IODD -o TARGET 2>/dev/null)
    if [ -z "$IODD_MOUNT" ]; then
        log "❌ Error: IODD device not detected. Please check your connection and try again."
        exit 1
    fi
}

# Ensure the main server is reachable
check_server_connection() {
    if ! ping -c 1 -W 2 "$(echo $SOURCE_SERVER | cut -d@ -f2 | cut -d: -f1)" &>/dev/null; then
        log "⚠ Warning: Unable to reach the main server. Please check your network."
        exit 1
    fi
}

# Display Sync Options
display_menu() {
    clear
    log "🔄 IODD Sync Tool - ServiceIT"
    echo -e "\nSelect a sync option:"
    echo "1) 🛠 Test Sync (Dry Run - No changes, only check errors)"
    echo "2) 🚀 Quick Full Update (Sync & Auto-Verify)"
    echo "3) 🛠 Selective Sync (Choose specific items)"
    echo "4) 🔍 Keep Specific Files/Folders & Sync Everything Else"
    echo "5) 🚪 Exit"
    read -p "Enter your choice [1-5]: " choice
}

# Function to let the user exclude files/folders from sync
select_exclusions() {
    log "🔍 Select files or folders to exclude from sync."
    rsync -avz --dry-run --list-only "$SOURCE_SERVER/" | awk '{print $NF}' > /tmp/sync_list.txt
    cat /tmp/sync_list.txt

    read -p "Enter file(s) or folder(s) to exclude (comma-separated): " exclude_input
    echo "$exclude_input" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "$EXCLUDE_FILE"
    log "✅ Selected exclusions: $(cat $EXCLUDE_FILE)"
}

# Test Sync Mode - Dry run, check for errors before actual sync
sync_test() {
    log "🛠 Running Test Sync (Dry Run)..."
    rsync -avz --dry-run --progress "$SOURCE_SERVER/" "$IODD_MOUNT/" | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✅ Test Sync completed successfully. No errors detected."
    else
        log "⚠ Rsync encountered errors. Please check the log before running a full sync."
        exit 1
    fi
}

# Full Sync - Overwrites IODD with the latest version from the main server
sync_full() {
    log "🔄 Performing Full Sync..."
    rsync -avz --progress --delete "$SOURCE_SERVER/" "$IODD_MOUNT/" | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✅ Full Sync completed successfully!"
    else
        log "⚠ Error: Full Sync encountered issues."
        exit 1
    fi
}

# Selective Sync - Prompts for specific directories/files to sync
sync_selective() {
    log "🛠 Performing Selective Sync..."
    rsync -avz --dry-run --progress --delete --ignore-existing "$SOURCE_SERVER/" "$IODD_MOUNT/" | awk '{print $NF}' > /tmp/sync_list.txt
    cat /tmp/sync_list.txt

    read -p "Enter directory or file to sync (exact match required): " selection
    if [ -n "$selection" ]; then
        rsync -avz --progress --delete "$SOURCE_SERVER/$selection" "$IODD_MOUNT/$selection" | tee -a "$LOG_FILE"
        log "✅ Selected item '$selection' synced successfully."
    else
        log "⚠ No selection made. Exiting selective sync."
    fi
}



# Keep Specific Files/Folders & Sync Everything Else
sync_keep_files() {
    select_exclusions  # Let the user choose files/folders to keep
    log "🔄 Syncing everything except exclusions..."
    rsync -avz --progress --delete --exclude-from="$EXCLUDE_FILE" "$SOURCE_SERVER/" "$IODD_MOUNT/" | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✅ Sync completed while keeping exclusions!"
    else
        log "⚠ Error: Sync encountered issues."
    fi
}

# Auto-Update: A fully automated sync + verification step
auto_update() {
    log "🚀 Auto-Updating IODD with the latest version..."
    sync_full  # Perform full sync first

    # Run a test sync afterward to verify the update
    log "🔍 Verifying sync integrity..."
    rsync -avz --dry-run --progress "$SOURCE_SERVER/" "$IODD_MOUNT/" | tee -a "$LOG_FILE"

    if [ $? -eq 0 ]; then
        log "✅ Auto-Update completed successfully. Your IODD is fully updated!"
    else
        log "⚠ Error: Auto-Update encountered issues."
        exit 1
    fi
}

# Ensure prerequisites are met
detect_iodd
check_server_connection
display_menu

# Handle user selection
case "$choice" in
    1) sync_test ;;
    2) auto_update ;;  # New automatic update option
    3) sync_selective ;;
    4) sync_keep_files ;;
    5) log "🚪 Exiting script. No sync performed." && exit 0 ;;
    *) log "⚠ Invalid choice. Exiting." && exit 1 ;;
esac
