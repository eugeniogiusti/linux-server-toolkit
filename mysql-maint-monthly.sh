#!/bin/bash

# Monthly MySQL maintenance script
# Performs OPTIMIZE TABLE on all tables in all databases

LOG_FILE="/var/log/mysql-maint-monthly.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting monthly MySQL maintenance (OPTIMIZE)" >> "$LOG_FILE"

# Get list of databases (excluding system DBs)
DATABASES=$(mysql -Bse "SHOW DATABASES;" | grep -Ev '^(information_schema|performance_schema|mysql|sys)$')

for DB in $DATABASES; do
    echo "[$DATE] Optimizing database: $DB" >> "$LOG_FILE"

    # Get all tables in database
    TABLES=$(mysql -Bse "USE $DB; SHOW TABLES;")

    for TABLE in $TABLES; do
        echo "  - Optimizing table: $TABLE" >> "$LOG_FILE"
        mysql -e "USE $DB; OPTIMIZE TABLE $TABLE;" >> "$LOG_FILE" 2>&1
    done
done

DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$DATE] Monthly MySQL maintenance completed" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
