#!/bin/bash

# SSH login notification script
# Monitors SSH access attempts and sends real-time Discord notifications with login details
# Uses PAM (Pluggable Authentication Modules) variables to capture login information
#
# Setup: Add this line to /etc/pam.d/sshd to trigger on every SSH login:
# session optional pam_exec.so /path/to/ssh-notify.sh
#
# The script captures:
# - Username who logged in ($PAM_USER)
# - Server hostname
# - IP address of the connection ($PAM_RHOST)
# - Timestamp of the access

# Configuration 
WEBHOOK_URL="Your_Discord_Webhook_URL_Here"

# Capture SSH login information from PAM variables
USERNAME="$PAM_USER"
HOSTNAME=$(hostname)
IP="${PAM_RHOST:-localhost}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Build Discord embed message with login details
MESSAGE="{
  \"content\": \"🔐 **New SSH access**\",
  \"embeds\": [{
    \"color\": 3447003,
    \"fields\": [
      {\"name\": \"User\", \"value\": \"$USERNAME\", \"inline\": true},
      {\"name\": \"Server\", \"value\": \"$HOSTNAME\", \"inline\": true},
      {\"name\": \"IP\", \"value\": \"$IP\", \"inline\": true},
      {\"name\": \"Timestamp\", \"value\": \"$TIMESTAMP\", \"inline\": false}
    ]
  }]
}"

# Send the notification to Discord
curl -H "Content-Type: application/json" \
     -d "$MESSAGE" \
     "$WEBHOOK_URL" &> /dev/null

exit 0
