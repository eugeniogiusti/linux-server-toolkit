#!/bin/bash

# Server log collection script for troubleshooting
# Collects system logs (PHP-FPM, MySQL, Apache, Laravel, Redis, syslog) and system info,
# compresses them into a zip file and sends to Discord for analysis

# === CONFIG ===
DISCORD_WEBHOOK="YOUR_DISCORD_WEBHOOK_URL_HERE"
HOSTNAME=$(hostname)
DATE=$(date +%Y%m%d_%H%M%S)
TODAY_LARAVEL=$(date +%Y-%m-%d)
TEMP_DIR="/tmp/logs_${DATE}"
ZIP_FILE="/tmp/server_logs_${DATE}.zip"

# === CREATE TEMPORARY DIRECTORY ===
mkdir -p $TEMP_DIR

# === COLLECT LOGS (last 300 lines) ===
echo "📦 Collecting logs..."

tail -300 /var/log/php8.4-fpm.log > $TEMP_DIR/php-fpm.log 2>/dev/null
tail -300 /var/log/mysql/slow.log > $TEMP_DIR/mysql-slow.log 2>/dev/null
tail -300 /var/log/mysql/error.log > $TEMP_DIR/mysql-error.log 2>/dev/null
tail -300 /var/log/apache2/error.log > $TEMP_DIR/apache-error.log 2>/dev/null
tail -300 /var/log/apache2/yourapp.log > $TEMP_DIR/yourapp.log 2>/dev/null
tail -300 /var/log/apache2/yourapp.log > $TEMP_DIR/yourapp.log 2>/dev/null
tail -300 /var/log/syslog > $TEMP_DIR/syslog.log 2>/dev/null
tail -300 /var/log/redis/redis-server.log > $TEMP_DIR/redis.log 2>/dev/null

# === TODAY'S LARAVEL LOGS ===
cp /var/www/laravel-app/storage/logs/laravel-${TODAY_LARAVEL}.log $TEMP_DIR/laravel-today.log 2>/dev/null
cp /var/www/laravel-app/storage/logs/security-${TODAY_LARAVEL}.log $TEMP_DIR/security-today.log 2>/dev/null

# === ADD SYSTEM INFO ===
cat > $TEMP_DIR/system-info.txt << EOF
=== SERVER INFO $(date) ===

RAM:
$(free -h)

CPU LOAD:
$(uptime)

DISK:
$(df -h | grep -E "/$|/var")

PHP-FPM PROCESSI:
$(ps aux | grep php-fpm | grep -v grep | wc -l) / 40

APACHE WORKERS:
$(ps aux | grep apache2 | grep -v grep | wc -l)
EOF

# === COMPRESS ===
cd /tmp
zip -r -q $ZIP_FILE logs_${DATE}/
rm -rf $TEMP_DIR

# === SEND TO DISCORD ===
echo "📤 Sending to Discord..."

FILE_SIZE=$(stat -c%s "$ZIP_FILE" 2>/dev/null || stat -f%z "$ZIP_FILE")
if [ $FILE_SIZE -gt 8388608 ]; then
    echo "❌ File too large (>8MB), Discord won't accept it"
    rm -f $ZIP_FILE
    exit 1
fi

curl -F "file=@${ZIP_FILE}" \
     -F "content=📊 Log server **${HOSTNAME}** - $(date '+%Y-%m-%d %H:%M:%S')" \
     $DISCORD_WEBHOOK

# === CLEANUP ===
rm -f $ZIP_FILE

echo "✅ Done!"
