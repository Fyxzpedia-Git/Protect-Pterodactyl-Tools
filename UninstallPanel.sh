#!/bin/bash

echo "================================================="
echo "   PREPARE CLEAN - PTERODACTYL REINSTALL MODE"
echo "================================================="
echo ""
echo "This will remove:"
echo "- Pterodactyl Panel"
echo "- Wings"
echo "- Docker"
echo "- MySQL / MariaDB"
echo "- Nginx"
echo "- Redis"
echo "- SSL"
echo "- Game servers"
echo "- Old backups"
echo ""
read -p "Type YES to continue: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "[1/6] Stopping services..."
systemctl stop wings nginx mysql mariadb redis-server docker containerd 2>/dev/null
systemctl disable wings nginx mysql mariadb redis-server docker containerd 2>/dev/null

echo "[2/6] Removing packages..."
apt purge -y nginx* mysql-server* mariadb-server* redis-server* docker* containerd* runc certbot php* 2>/dev/null
apt autoremove -y
apt clean

echo "[3/6] Removing panel & wings directories..."
rm -rf /var/www/pterodactyl
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
rm -rf /srv/daemon-data
rm -rf /usr/local/bin/wings
rm -rf /etc/systemd/system/wings.service

echo "[4/6] Removing Docker data..."
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker

echo "[5/6] Removing database & nginx..."
rm -rf /etc/mysql
rm -rf /var/lib/mysql
rm -rf /etc/nginx
rm -rf /etc/letsencrypt
rm -rf /var/log/nginx
rm -rf /var/log/mysql

echo "[6/6] Removing old backups & archives..."
rm -rf /var/backups/*
find /home -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.tar.gz" -o -name "*.sql" \) -delete 2>/dev/null
find /root -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.tar.gz" -o -name "*.sql" \) -delete 2>/dev/null

systemctl daemon-reload
systemctl reset-failed

echo ""
echo "==============================================="
echo " SYSTEM CLEAN & READY FOR REINSTALL"
echo "==============================================="
df -h

echo ""
echo "Verification:"
which docker
which mysql
which nginx
which wings

echo ""
echo "Now you can safely run:"
echo "bash <(curl -s https://pterodactyl-installer.se)"
