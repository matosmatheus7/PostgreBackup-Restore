#!/bin/bash

##########################################################
# Script Name: pgbackup.sh
# Description: This script is used to create backups of
#              specified tables (partitioned or not) and 
#              store them in a remote server.
# Author: Matheus Matos
# Date: September 01, 2023
##########################################################

# Postgree connection variables
PGHOST="PGHOST"
PGPORT="PGPORT"
PGUSER="PGUSER"
PGPASSWORD="PGPASSWORD"
DATABASE="DATABASE"

# local backup directory path
BACKUP_DIR="BACKUP_DIR"

# Remote backup directory (SSH KEY ENABLED)
REMOTE_HOST="REMOTE_HOST"
REMOTE_USER="REMOTE_USER"
REMOTE_DIR="REMOTE_DIR"

# Backup table list
TABLE_LIST="tablelist.txt"

# Log File
LOG_FILE="pgbackup-$(date +%Y%m%d_%H%M).log"

# Function to backup tables and their partitions, if any exist
backup_table() {
    table_name="$1"

    # Get number of partitions
    num_partitions=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" -t -c "SELECT count(*) FROM pg_catalog.pg_inherits WHERE inhparent = '$table_name'::regclass")

    if [ "$num_partitions" -eq 0 ]; then
        dump_table "$table_name"
    else
        dump_table "$table_name"
        # List existing partitions
        partitions=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" -t -c "SELECT relname FROM pg_class WHERE relkind = 'r' AND relname LIKE '$table_name%'")
        for partition in $partitions; do
            dump_table "$partition"
        done
    fi
}

# Function that dump table data to a file
dump_table() {
    table_name="$1"
    start_time=$(date +%s)
    
    echo "Starting Backup of table $table_name ..." | tee -a "$LOG_FILE"

    pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" -t "$table_name" -F c -f "$BACKUP_DIR/$table_name.sql" 2>> "$LOG_FILE"

    # Get table size
    size=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" -t -c "SELECT pg_size_pretty(pg_total_relation_size('$table_name'))")
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    
    echo "Backup of table $table_name ($size) completed in $elapsed_time seconds" | tee -a "$LOG_FILE"
    
    scp_backup_file "$table_name"
}

# Copy file to remote host
scp_backup_file() {
    file_name="$1"
    scp "$BACKUP_DIR/$file_name.sql" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
    remove_backup_file "$file_name"
}

# Delete files from local backup file
remove_backup_file() {
    file_name="$1"
    rm -f "$BACKUP_DIR/$file_name.sql"
}

# Compress .sql files on remote dir
zip_remote_sql_files() {
    timestamp=$(date +%Y%m%d_%H%M)
    ssh "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && tar -czf pgbackup-$timestamp.tar.gz *.sql && rm -f *.sql"
    echo "Log are compressed on the remote dir, file pgbackup-$timestamp.tar.gz" | tee -a "$LOG_FILE"
}

# Check if table list exists
if [ ! -f "$TABLE_LIST" ]; then
    echo "Table list file '$TABLE_LIST' not found."
    exit 1
fi

# Create the backup dir
mkdir -p "$BACKUP_DIR"
echo "Backup started at $(date)" | tee -a "$LOG_FILE"

# Start the backing up each table of the file
while IFS= read -r table; do
    backup_table "$table"
done < "$TABLE_LIST"

echo "Backup completed at $(date)" | tee -a "$LOG_FILE"
zip_remote_sql_files
echo "Backup finished. Files are compressed, logs are in '$LOG_FILE'." | tee -a "$LOG_FILE"

