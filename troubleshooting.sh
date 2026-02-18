#!/bin/bash

# Server log collection script for troubleshooting
# Collects system logs (PHP-FPM, MySQL, Apache, Laravel, Redis, syslog) and system info,
# compresses them into a zip file and sends to Discord for analysis

# === CONFIG ===
# ⚙️  Edit the values below before running the script:
#   - DISCORD_WEBHOOK: your Discord webhook URL
#   - APP_NAME: your Apache virtual host log name (e.g. myapp → /var/log/apache2/myapp.log)
#   - PHP_VERSION: your PHP version (e.g. 8.4)
#   - LOG_DIR: path to system logs (default: /var/log)
#   - LARAVEL_LOG_DIR: path to your Laravel logs directory
DISCORD_WEBHOOK="YOUR_DISCORD_WEBHOOK_URL_HERE"
APP_NAME="yourapp"
PHP_VERSION="8.4"
HOSTNAME=$(hostname)
DATE=$(date +%Y%m%d_%H%M%S)
TODAY_LARAVEL=$(date +%Y-%m-%d)
TEMP_DIR="/tmp/logs_${DATE}"
ZIP_FILE="/tmp/server_logs_${DATE}.zip"
LOG_DIR="/var/log"
LARAVEL_LOG_DIR="/var/www/laravel-app/storage/logs"

# === CREATE TEMPORARY DIRECTORY ===
mkdir -p $TEMP_DIR

# === COLLECT LOGS (last 300 lines) ===
echo "📦 Collecting logs..."

tail -300 $LOG_DIR/php${PHP_VERSION}-fpm.log > $TEMP_DIR/php-fpm.log 2>/dev/null
tail -300 $LOG_DIR/mysql/slow.log > $TEMP_DIR/mysql-slow.log 2>/dev/null
tail -300 $LOG_DIR/mysql/error.log > $TEMP_DIR/mysql-error.log 2>/dev/null
tail -300 $LOG_DIR/apache2/error.log > $TEMP_DIR/apache-error.log 2>/dev/null
tail -300 $LOG_DIR/apache2/${APP_NAME}.log > $TEMP_DIR/${APP_NAME}.log 2>/dev/null
tail -300 $LOG_DIR/syslog > $TEMP_DIR/syslog.log 2>/dev/null
tail -300 $LOG_DIR/redis/redis-server.log > $TEMP_DIR/redis.log 2>/dev/null

# === TODAY'S LARAVEL LOGS ===
cp $LARAVEL_LOG_DIR/laravel-${TODAY_LARAVEL}.log $TEMP_DIR/laravel-today.log 2>/dev/null
cp $LARAVEL_LOG_DIR/security-${TODAY_LARAVEL}.log $TEMP_DIR/security-today.log 2>/dev/null

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
