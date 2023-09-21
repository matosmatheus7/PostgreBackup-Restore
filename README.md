# PostgreSQL Backup and Restore Scripts

Welcome to the PostgreSQL Backup and Restore Scripts repository! This collection of user-friendly scripts and comprehensive documentation is designed to simplify the management of backups and streamline database recovery for PostgreSQL.

## Usage Instructions

### `pgbackup.sh`

#### Description

The `pgbackup.sh` script enables the creation of backups for specified tables, whether they are partitioned or not. These backups are securely stored on a remote server. To ensure smooth operation, please ensure that SSH keys are enabled between the servers.

**Before running the script:**

-   Create a `table_list.txt` file in the script directory containing the names of the tables you want to back up.
-   Customize the script variables to align with your specific requirements.

Upon execution, the script will generate a log file detailing the backup process.

**Usage:** To initiate the backup process, run the following command with root privileges:

bash

`./pgbackup.sh` 

### `pgrestore.sh`

#### Description

The `pgrestore.sh` script is designed to facilitate database restoration operations from a remote server. It retrieves and restores `.sql` files stored in a specified remote directory. Just like the backup script, SSH keys should be enabled between the servers to ensure seamless operation.

**Before running the script:**

-   Configure the script variables to match your restoration needs.

Upon execution, the script will generate a log file detailing the restoration process.

**Usage:** To begin the database restoration process, execute the following command with root privileges:

bash

```bash
./pgrestore.sh
```
