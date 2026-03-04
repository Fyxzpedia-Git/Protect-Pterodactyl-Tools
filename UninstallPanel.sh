#!/bin/bash

clear
echo "========================================"
echo "     PTERODACTYL FULL UNINSTALLER"
echo "========================================"
echo ""
echo "WARNING: Ini akan menghapus PANEL & WINGS sepenuhnya!"
echo ""

read -p "Lanjutkan uninstall? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Dibatalkan."
    exit 1
fi

echo ""
echo "Stopping services..."
systemctl stop nginx 2>/dev/null
systemctl stop php8.3-fpm 2>/dev/null
systemctl stop php8.2-fpm 2>/dev/null
systemctl stop php8.1-fpm 2>/dev/null
systemctl stop wings 2>/dev/null
systemctl stop mariadb 2>/dev/null

echo ""
echo "Removing Pterodactyl panel files..."
rm -rf /var/www/pterodactyl

echo ""
echo "Removing Wings files..."
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
rm -f /etc/systemd/system/wings.service

echo ""
echo "Removing Nginx configuration..."
rm -f /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-available/pterodactyl.conf

echo ""
echo "Cleaning SSL certificates..."
rm -rf /etc/letsencrypt
rm -f /etc/ssl/*.pem
rm -f /etc/ssl/*.key

echo ""
echo "Reloading systemd..."
systemctl daemon-reload

echo ""
echo "Cleaning database..."

if systemctl list-unit-files | grep -q mariadb; then
    echo "MariaDB detected."

    if ! systemctl is-active --quiet mariadb; then
        echo "Starting MariaDB..."
        systemctl start mariadb
        sleep 3
    fi

    if mysqladmin ping --silent; then
        mysql -u root <<EOF
DROP DATABASE IF EXISTS panel;
DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';
DROP USER IF EXISTS 'pterodactyl'@'localhost';
FLUSH PRIVILEGES;
EOF
        echo "Database cleaned successfully."
    else
        echo "MariaDB running but cannot access MySQL. Skipping database cleanup."
    fi
else
    echo "MariaDB not installed. Skipping database cleanup."
fi

echo ""
echo "Autoremoving unused packages..."
apt autoremove -y
apt autoclean -y

echo ""
echo "Restarting nginx..."
systemctl restart nginx 2>/dev/null

echo ""
echo "========================================"
echo "     UNINSTALL COMPLETE ✅"
echo "========================================"
echo ""
echo "Server sekarang bersih dan siap install ulang."
