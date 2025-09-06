#!/bin/bash

# Function to check if SQL Server is ready
check_sql_server_ready() {
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No -Q "SELECT 1" >/dev/null 2>&1
    return $?
}

# Start SQL Server in background
echo "Starting SQL Server..."
/opt/mssql/bin/sqlservr &
SQL_PID=$!

# Wait for SQL Server to be ready with timeout
echo "Waiting for SQL Server to be ready..."
MAX_ATTEMPTS=60  # Maximum attempts (60 * 2 seconds = 2 minutes timeout)
ATTEMPT=0
READY=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if check_sql_server_ready; then
        READY=true
        echo "SQL Server is ready!"
        break
    fi

    # Check if SQL Server process is still running
    if ! kill -0 $SQL_PID 2>/dev/null; then
        echo "ERROR: SQL Server process has died unexpectedly"
        exit 1
    fi

    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS - SQL Server not ready yet, waiting..."
    sleep 2
done

if [ "$READY" = false ]; then
    echo "ERROR: SQL Server failed to start within the timeout period"
    exit 1
fi

# Check logical file names in the backup
echo "Checking backup file structure..."
if ! /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No \
   -Q "RESTORE FILELISTONLY FROM DISK = \"/var/opt/mssql/backup/BikeZ_DB.bak\""; then
    echo "ERROR: Failed to read backup file structure"
    exit 1
fi

# Restore the database with proper file paths
echo "Restoring BikeZ_DB database..."
if ! /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No \
   -Q "RESTORE DATABASE BikeZ_DB FROM DISK = \"/var/opt/mssql/backup/BikeZ_DB.bak\"
       WITH REPLACE,
       MOVE 'BikeZ' TO '/var/opt/mssql/data/BikeZ.mdf',
       MOVE 'BikeZ_log' TO '/var/opt/mssql/data/BikeZ_log.ldf'"; then
    echo "ERROR: Database restore failed"
    exit 1
fi

echo "Database restore completed successfully."

# Keep the container running
wait