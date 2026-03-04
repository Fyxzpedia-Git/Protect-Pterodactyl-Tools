#!/bin/bash

clear
echo "========================================"
echo "     AUTO INSTALL PTERODACTYL PANEL"
echo "========================================"
echo ""

read -p "Masukkan Domain Panel (contoh: panel.domain.com): " PANEL_DOMAIN
read -p "Masukkan Domain Node (contoh: node.domain.com): " NODE_DOMAIN
read -p "Masukkan Password Admin: " ADMIN_PASS

echo ""
echo "Updating system..."
apt update -y && apt upgrade -y

echo ""
echo "Installing dependencies..."
apt install -y curl wget git unzip tar nginx mariadb-server redis-server \
php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-gd php8.3-mbstring \
php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip

# =========================
# INSTALL PANEL
# =========================

echo ""
echo "Installing Panel..."

bash <(curl -s https://pterodactyl-installer.se) <<EOF
0


1248
Asia/Jakarta
admin@gmail.com
admin@gmail.com
admin
admin
admin
$ADMIN_PASS
$PANEL_DOMAIN
y
y
y
y
y

1
Y
EOF

# =========================
# INSTALL WINGS
# =========================

echo ""
echo "Installing Wings..."

bash <(curl -s https://pterodactyl-installer.se) <<EOF
1
y
y
y
$PANEL_DOMAIN
y
user
1248
y
$NODE_DOMAIN
y
admin@gmail.com
y
EOF

echo ""
echo "========================================"
echo "      INSTALLATION COMPLETE ✅"
echo "========================================"
echo ""
echo "Panel: https://$PANEL_DOMAIN"
echo "Node : https://$NODE_DOMAIN"
echo "Email: admin@gmail.com"
echo "Password: $ADMIN_PASS"
