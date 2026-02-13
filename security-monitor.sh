#!/bin/bash

# Security monitoring script for Linux servers
# Monitors system security changes including: new user creation, sudoers modifications,
# and critical system file changes. Sends Discord alerts with details about who made the changes.

# ============================================
# SECURITY MONITOR
# ============================================

WEBHOOK_URL="YOUR_DISCORD_WEBHOOK_URL_HERE"
HOSTNAME=$(hostname)

# File to track previous state
STATE_DIR="/var/log/security-monitor"
mkdir -p "$STATE_DIR"

# Function to find who performed the action
find_culprit() {
    local auth_log="/var/log/auth.log"
    
    # Search for the last executed sudo command (excluding this script)
    local sudo_line=$(grep "sudo:" "$auth_log" | grep "COMMAND=" | grep -v "security-monitor.sh" | tail -1)
    
    # Extract the user from the line: "sudo:  eugenio : TTY=..."
    local user=$(echo "$sudo_line" | grep -oP "sudo:\s+\K\w+(?=\s+:)")
    
    # Extract the command: "COMMAND=/usr/sbin/useradd test"
    local command=$(echo "$sudo_line" | grep -oP "COMMAND=\K.*")
    
    # Search for the IP of that user's last SSH connection
    local ip=""
    if [ ! -z "$user" ]; then
        ip=$(grep "Accepted.*for $user from" "$auth_log" | tail -1 | grep -oP "from \K[\d.]+")
    fi
    
    # Build the message
    local culprit_info=""
    if [ ! -z "$user" ]; then
        culprit_info="**User:** \`$user\`\n"
    fi
    if [ ! -z "$ip" ]; then
        culprit_info="${culprit_info}**IP:** \`$ip\`\n"
    fi
    if [ ! -z "$command" ]; then
        culprit_info="${culprit_info}**Command:** \`$command\`\n"
    fi
    
    # If we don't find anything, say so
    if [ -z "$culprit_info" ]; then
        culprit_info="**Info:** Change detected but author not found in recent logs\n"
    fi
    
    echo "$culprit_info"
}

# Function to send Discord notification
send_alert() {
    local title="$1"
    local message="$2"
    local color="$3"
    local culprit="$4"
    
    local full_message="${message}\n\n${culprit}**Time:** \`$(date '+%Y-%m-%d %H:%M:%S')\`"
    
    curl -H "Content-Type: application/json" \
         -d "{
           \"embeds\": [{
             \"title\": \"$title\",
             \"description\": \"$full_message\",
             \"color\": $color,
             \"footer\": {\"text\": \"Server: $HOSTNAME\"},
             \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
           }]
         }" \
         "$WEBHOOK_URL" &> /dev/null
}

# ============================================
# 1. MONITOR NEW USERS
# ============================================
check_new_users() {
    local current_users=$(cut -d: -f1 /etc/passwd | sort)
    local user_file="$STATE_DIR/users.txt"
    
    if [ -f "$user_file" ]; then
        local previous_users=$(cat "$user_file")
        local new_users=$(comm -13 <(echo "$previous_users") <(echo "$current_users"))
        
        if [ ! -z "$new_users" ]; then
            local culprit=$(find_culprit)
            send_alert "🚨 NEW USER CREATED" \
                      "**Added users:**\n\`\`\`$new_users\`\`\`" \
                      15158332 \
                      "$culprit"
        fi
    fi
    
    echo "$current_users" > "$user_file"
}

# ============================================
# 2. MONITOR SUDOERS
# ============================================
check_sudoers() {
    local sudoers_hash=$(md5sum /etc/sudoers 2>/dev/null | cut -d' ' -f1)
    local sudoers_d_hash=$(find /etc/sudoers.d/ -type f -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
    local hash_file="$STATE_DIR/sudoers.hash"
    
    if [ -f "$hash_file" ]; then
        local previous_hash=$(cat "$hash_file")
        local current_hash="${sudoers_hash}${sudoers_d_hash}"
        
        if [ "$previous_hash" != "$current_hash" ]; then
            local culprit=$(find_culprit)
            send_alert "⚠️ SUDOERS CHANGES" \
                      "The /etc/sudoers or /etc/sudoers.d/ file has been modified!" \
                      15844367 \
                      "$culprit"
        fi
    fi
    
    echo "${sudoers_hash}${sudoers_d_hash}" > "$hash_file"
}

# ============================================
# 3. MONITOR CRITICAL FILES
# ============================================
check_critical_files() {
    local files=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/mysql/my.cnf"
    "/etc/apache2/apache2.conf"
    "/etc/apache2/sites-enabled/*.conf"
    "/etc/ssh/sshd_config"
)
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi
        
        local current_hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
        local hash_file="$STATE_DIR/$(echo $file | sed 's/\//_/g').hash"
        
        if [ -f "$hash_file" ]; then
            local previous_hash=$(cat "$hash_file")
            
            if [ "$previous_hash" != "$current_hash" ]; then
                local culprit=$(find_culprit)
                send_alert "🔴 CRITICAL FILE MODIFIED" \
                          "**File:** \`$file\`\n**Action:** Verify changes immediately" \
                          15158332 \
                          "$culprit"
            fi
        fi
        
        echo "$current_hash" > "$hash_file"
    done
}

# ============================================
# RUN ALL CHECKS
# ============================================
check_new_users
check_sudoers
check_critical_files

echo "[$(date)] Security checks completed" >> "$STATE_DIR/file-changes.log"
