#!/bin/bash

echo "========================================"
echo "  PTERODACTYL FULL CLEANER SCRIPT"
echo "========================================"
echo ""

read -p "Yakin mau hapus SEMUA panel & wings? (y/n): " confirm
if [[ $confirm != "y" ]]; then
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
echo "Removing Pterodactyl files..."
rm -rf /var/www/pterodactyl
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl

echo ""
echo "Removing Nginx configs..."
rm -f /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-available/pterodactyl.conf

echo ""
echo "Cleaning SSL leftovers..."
rm -rf /etc/letsencrypt
rm -f /etc/ssl/*.pem
rm -f /etc/ssl/*.key

echo ""
echo "Removing Wings service..."
rm -f /etc/systemd/system/wings.service
systemctl daemon-reload

echo ""
echo "Cleaning database..."
mysql -u root <<EOF
DROP DATABASE IF EXISTS panel;
DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';
DROP USER IF EXISTS 'pterodactyl'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ""
echo "Autoremove unused packages..."
apt autoremove -y
apt autoclean -y

echo ""
echo "Restarting nginx..."
systemctl restart nginx 2>/dev/null

echo ""
echo "========================================"
echo "  CLEANING COMPLETE ✅"
echo "========================================"
echo ""
echo "Server siap untuk install ulang panel."
