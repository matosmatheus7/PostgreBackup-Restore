#!/bin/bash

##########################################################
# Script Name: pgrestore.sh
# Description: This script is used to perform a database
#              restore operation from a remote server.
# Author: Matheus Matos
# Date: September 05, 2023
##########################################################

# PG Connection Info
PGHOST="PGHOST"
PGPORT="PGPORT"
PGUSER="PGUSER"
PGPASSWORD="PGPASSWORD"
DATABASE="DATABASE"

# Local restore dir path
RESTORE_DIR="RESTORE_DIR"

# Remote host connection info
REMOTE_HOST="REMOTE_HOST"
REMOTE_USER="REMOTE_USER"
REMOTE_DIR="REMOTE_DIR"

LOG_FILE="pgrestore-log_$(date +%Y%m%d_%H%M).txt"

# Function that restore table from a file
restore_table() {
    file_name="$1"
    start_time=$(date +%s)

    echo "Starting the restore of $file_name ..."  | tee -a "$LOG_FILE"

    pg_restore -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" "$restore_option" "$RESTORE_DIR/$file_name" 2>> "$LOG_FILE"

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    echo "Restored $file_name completed in $elapsed_time seconds." | tee -a "$LOG_FILE"

    remove_backup_file "$file_name"
}

# Copy file from remote host
scp_restore_file() {
    file_name="$1"
    scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$file_name" "$RESTORE_DIR/$file_name"
}

# Delete files from local restore file
remove_backup_file() {
    file_name="$1"
    rm -rf "$RESTORE_DIR/$file_name"
}

echo "Database Restore Options:"
echo "------------------------"
echo "Select an option for the database restore process:"
echo "Make sure that all backup files (.sql) are on the $REMOTE_DIR on $REMOTE_HOST."
echo
echo "1) Drop existing tables and perform a clean restore."
echo "   This option will delete all existing data and replace it with the restored data."
echo
echo "2) Append data to existing tables."
echo "   This option will add the restored data to the existing data without removing anything."
echo
# Prompt user for restore option until a valid choice is made
while true; do
    read -p "Enter your choice (1/2): " restore_option
    case "$restore_option" in
        1)
            restore_option="--clean"
            break
            ;;
        2)
            restore_option="--data-only"
            break
            ;;
        *)
            echo "Invalid choice. Please select '1' or '2'."
            ;;
    esac
done

# list files on the remote server
file_list=$(ssh "$REMOTE_USER@$REMOTE_HOST" "ls -tr $REMOTE_DIR/*.sql")

# Check if any files were found
if [[ -z "$file_list" ]]; then
    echo "No matching .sql files found in $REMOTE_DIR. Script will exit."
    exit 1
fi

> "$LOG_FILE"

# Create the restore dir
mkdir -p "$RESTORE_DIR"
echo " Restore Started at $(date)" | tee -a "$LOG_FILE"

# Process the found files
while read -r remote_file; do
    file_name=$(basename "$remote_file")
    scp_restore_file "$file_name"
    restore_table "$file_name"
done <<< "$file_list"

echo "Restore Completed at $(date)" | tee -a "$LOG_FILE"

