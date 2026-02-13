#!/bin/bash

# System updates checker script
# Checks for available apt package updates and sends Discord notifications with the list of upgradable packages

# Discord webhook URL
DISCORD_WEBHOOK="Your_Discord_Webhook_URL_Here"

# Hostname of the server
HOSTNAME=$(hostname)

# Execute apt update
apt update > /dev/null 2>&1

# Count the number of upgradable packages
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")

# if there are upgradable packages, send a notification
if [ $UPGRADABLE -gt 0 ]; then
    # Get the list of packages (one line, comma-separated)
    PACKAGE_LIST=$(apt list --upgradable 2>/dev/null | grep "upgradable" | cut -d'/' -f1 | head -20 | paste -sd ',' -)

    # Send to Discord (all on one line)
    if [ $UPGRADABLE -gt 20 ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"🔔 **Server: $HOSTNAME** - **$UPGRADABLE updates available**\n\nTop 20: \`$PACKAGE_LIST\` ...\"}" \
             $DISCORD_WEBHOOK
    else
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"🔔 **Server: $HOSTNAME** - **$UPGRADABLE updates available**\n\nPackets: \`$PACKAGE_LIST\`\"}" \
             $DISCORD_WEBHOOK
    fi
fi
