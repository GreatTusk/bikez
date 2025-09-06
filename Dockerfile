FROM mcr.microsoft.com/mssql/server:2025-latest
USER root
RUN mkdir -p /var/opt/mssql/backup
COPY BikeZ_DB.bak /var/opt/mssql/backup/
COPY restore-db.sh /restore-db.sh
RUN chmod +x /restore-db.sh
USER mssql
EXPOSE 1433
ENTRYPOINT ["/restore-db.sh"]