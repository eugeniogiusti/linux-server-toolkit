# 🛠️ Linux Server Toolkit

![Status](https://img.shields.io/badge/status-stable-brightgreen)
![Last Commit](https://img.shields.io/github/last-commit/eugeniogiusti/linux-server-toolkit)
![License](https://img.shields.io/github/license/eugeniogiusti/linux-server-toolkit)
![Top Language](https://img.shields.io/github/languages/top/eugeniogiusti/linux-server-toolkit)
![Stars](https://img.shields.io/github/stars/eugeniogiusti/linux-server-toolkit?style=social)
![Bash](https://img.shields.io/badge/made%20with-Bash-4EAA25)

Production-tested automation scripts for server administration, security hardening, and maintenance.

![Linux Server](screenshots/linux.png)


## 📦 What's Inside

### 🔐 Security & Monitoring
- **SSH Login Notifications** (`ssh-notify.sh`) - Instant Discord alerts on every SSH access
- **Security Monitor** (`security-monitor.sh`) - Automated security checks and threat detection
- **ModSecurity Updates** (`update-modsec-crs.sh`) - Keep OWASP CRS rules up to date
- **OWASP Update Checker** (`check-owasp-updates.sh`) - Monitor for new security rule releases
- **CrowdSec Setup** (`crowdsec-setup.sh`) - Install CrowdSec + firewall bouncer, enable services, and run post-install checks

### 🗄️ Database Maintenance
- **MySQL Monthly Optimizer** (`mysql-maint-monthly.sh`) - Automated OPTIMIZE TABLE on all databases for better performance

### 🔄 System Maintenance  
![Server Maintenance](screenshots/server.png)

- **System Update Checker** (`check-updates.sh`) - Monitor available system updates

## 🎯 Perfect For

- **LAMP Stack Administrators** - Tools specifically designed for Linux/Apache/MySQL/PHP-laravel environments
- **Small-to-Medium Server Management** - Lightweight scripts that don't require complex orchestration
- **Security-Conscious Sysadmins** - Stay on top of security updates and access monitoring
- **Automated Maintenance** - Set it and forget it with cron jobs

## Quick Start

1. **Clone the repository**
```bash
   git clone https://github.com/eugeniogiusti/linux-server-toolkit
   cd linux-server-toolkit
```

2. **Choose your scripts**
```bash
   # Example: Install SSH notifications
   sudo cp ssh-notify.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/ssh-notify.sh
```

3. **Configure**
   - Edit scripts to add your Discord webhook URLs
   - Set up cron jobs for automated execution

4. **Test**
```bash
   # Most scripts can be run manually for testing
   sudo /usr/local/bin/ssh-notify.sh
```

## 📋 Requirements

- Ubuntu/Debian-based systems (tested on Ubuntu 20.04+)
- Bash 4.0+
- MySQL/MariaDB (for database scripts)
- curl (for Discord notifications)
- Discord webhook (optional, for notifications)
- `apt` + `systemd` required for `crowdsec-setup.sh`


⭐ **If these scripts save you time, consider giving the repo a star!**
