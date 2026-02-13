#!/bin/bash

# OWASP ModSecurity Core Rule Set (CRS) update script
# Safely updates the OWASP CRS to the latest version from the git repository
#
# The script performs:
# 1. Backs up current configuration (crs-setup.conf)
# 2. Checks current version and available updates
# 3. Shows changelog and asks for confirmation
# 4. Pulls latest changes from git
# 5. Tests Apache config and reloads if valid
#
# Usage: sudo ./update-modsec-crs.sh

echo "=== OWASP CRS Update Script ==="
echo "Date: $(date)"
echo ""

# Backup custom configuration
echo "[1/5] Backing up configuration..."
cp /etc/modsecurity/coreruleset/crs-setup.conf /etc/modsecurity/coreruleset/crs-setup.conf.backup-$(date +%Y%m%d)

# Go to CRS directory
cd /etc/modsecurity/coreruleset

# Check current version
echo "[2/5] Current version:"
git log --oneline -1

# Fetch updates from remote
echo "[3/5] Checking for updates..."
git fetch origin

# Count new commits available
NEW_COMMITS=$(git rev-list HEAD..origin/main --count)

if [ "$NEW_COMMITS" -eq 0 ]; then
    echo "✅ Already up to date! No updates available."
    exit 0
fi

echo "📦 Found $NEW_COMMITS new commits!"
echo ""
echo "Changelog:"
git log HEAD..origin/main --oneline

# Ask for confirmation before applying updates
read -p "Do you want to apply the updates? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Update canceled."
    exit 1
fi

# Apply updates via git pull
echo "[4/5] Applying updates..."
git pull origin main

# Test Apache config and reload if valid
echo "[5/5] Reload Apache..."
apachectl configtest
if [ $? -eq 0 ]; then
    systemctl reload apache2
    echo "✅ Update completed!"
    echo "New version: $(git log --oneline -1)"
else
    echo "❌ ERROR: Invalid Apache config!"
    echo "Restore backup if necessary."
    exit 1
fi
