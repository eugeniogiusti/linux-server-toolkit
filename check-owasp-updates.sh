#!/bin/bash

# Script to check for OWASP ModSecurity Core Rule Set (CRS) updates
# Monitors the git repository for new commits and sends Discord notifications when updates are available

# Discord webhook URL
DISCORD_WEBHOOK="Your_Discord_Webhook_URL_Here"

# Server hostname
HOSTNAME=$(hostname)

# OWASP CRS directory
CRS_DIR="/etc/modsecurity/coreruleset"

# Go to directory
cd $CRS_DIR

# Current version
CURRENT_VERSION=$(git log --oneline -1)

# Fetch updates (silently)
git fetch origin > /dev/null 2>&1

# Count new commits
NEW_COMMITS=$(git rev-list HEAD..origin/main --count)

# If there are updates, send notification
if [ "$NEW_COMMITS" -gt 0 ]; then
    # Get new commit titles
    COMMIT_LIST=$(git log HEAD..origin/main --oneline --pretty=format:"%h - %s" | head -10)
    
    # Prepare Discord message
    if [ "$NEW_COMMITS" -gt 10 ]; then
        MESSAGE="🔒 **Server: $HOSTNAME**

**OWASP CRS - $NEW_COMMITS new commits available**

Current version: \`$CURRENT_VERSION\`

Last 10 commits:
\`\`\`
$COMMIT_LIST
...
\`\`\`

Run: \`sudo /usr/local/bin/update-owasp-crs.sh\`"
    else
        MESSAGE="🔒 **Server: $HOSTNAME**

**OWASP CRS - $NEW_COMMITS new commits available**

Current version: \`$CURRENT_VERSION\`

Commit:
\`\`\`
$COMMIT_LIST
\`\`\`

Run: \`sudo /root/update-modsec-crs.sh\`"
    fi
    
    # Escape for JSON
    ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
    
    # Send to Discord
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$ESCAPED_MESSAGE\"}" \
         $DISCORD_WEBHOOK
fi
