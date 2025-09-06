#!/bin/bash

# Start SQL Server in background
/opt/mssql/bin/sqlservr &

# Wait for SQL Server to be ready
echo "Waiting for SQL Server to start..."
sleep 10

# Check logical file names in the backup
echo "Checking backup file structure..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No \
   -Q "RESTORE FILELISTONLY FROM DISK = \"/var/opt/mssql/backup/BikeZ_DB.bak\""

# Restore the database with proper file paths
echo "Restoring BikeZ_DB database..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No \
   -Q "RESTORE DATABASE BikeZ_DB FROM DISK = \"/var/opt/mssql/backup/BikeZ_DB.bak\"
       WITH REPLACE,
       MOVE 'BikeZ' TO '/var/opt/mssql/data/BikeZ.mdf',
       MOVE 'BikeZ_log' TO '/var/opt/mssql/data/BikeZ_log.ldf'"

echo "Database restore completed."

# Keep the container running
wait