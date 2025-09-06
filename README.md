# BikeZ Database

SQL Server container with automatic database restore from backup.

## Quick Start

```bash
docker compose up --build
```

## Connection Details

- **Server**: `localhost:1433`
- **Username**: `sa`
- **Password**: `MyPassword.123`
- **Database**: `BikeZ_DB`

## What It Does

1. Starts SQL Server 2025
2. Waits for server to be ready
3. Restores `BikeZ_DB` from backup automatically
4. Exposes database on port 1433

## Files

- `BikeZ_DB.bak` - Database backup file
- `restore-db.sh` - Restore script with health checks
- `Dockerfile` - Container build configuration
- `docker-compose.yml` - Service orchestration

Connect with any SQL Server client using the connection details above.

## Creating a Backup of the Database

Run the following command to back up the DW_BikeZ database inside the container:

```bash
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P MyPassword.123 -No -Q "BACKUP DATABASE [DW_BikeZ] TO DISK = N'/var/opt/mssql/data/DW_BikeZ.bak' WITH FORMAT, INIT
```

Copy the backup file to your host machine:

```bash
docker cp sqlserver:/var/opt/mssql/data/DW_BikeZ.bak ./DW_BikeZ.bak
```

### Verifying the Backup

Optionally, verify that the backup is valid:

```bash
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P MyPassword.123 -No -Q "RESTORE VERIFYONLY FROM DISK = '/var/opt/mssql/data/DW_BikeZ.bak'"
```
A valid backup will return:

```bash
The backup set on file 1 is valid.
```

### Restore

```bash
# Copy backup file from host to container
docker cp ./DW_BikeZ.bak sqlserver:/var/opt/mssql/data/DW_BikeZ.bak

# Restore the database
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P MyPassword.123 -No -Q "RESTORE DATABASE [DW_BikeZ] FROM DISK = N'/var/opt/mssql/data/DW_BikeZ.bak' WITH REPLACE"
```