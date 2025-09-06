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