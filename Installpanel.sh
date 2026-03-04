#!/bin/bash

clear
echo "========================================"
echo "      AUTO INSTALL PTERODACTYL"
echo "========================================"

read -p "Masukkan Domain Panel: " DOMAIN
read -p "Masukkan Email SSL: " EMAIL
read -p "Masukkan Password Admin: " PASSWORD

SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(getent hosts $DOMAIN | awk '{ print $1 }')

echo ""
echo "Checking domain DNS..."

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo "❌ ERROR: Domain tidak mengarah ke IP VPS"
    echo "Domain IP: $DOMAIN_IP"
    echo "Server IP: $SERVER_IP"
    exit 1
fi

echo "✅ DNS OK"

echo ""
echo "Updating system..."
apt update -y && apt upgrade -y

echo "Installing dependencies..."
apt install -y curl wget git unzip tar nginx mariadb-server redis-server \
certbot python3-certbot-nginx

systemctl enable nginx
systemctl start nginx

echo ""
echo "Installing Panel..."
bash <(curl -s https://pterodactyl-installer.se) <<EOF
0


1248
Asia/Jakarta
$EMAIL
$EMAIL
admin
admin
admin
$PASSWORD
$DOMAIN
n
n
n
n
n

1
EOF

echo ""
echo "Restarting Nginx..."
systemctl restart nginx

echo ""
echo "Requesting SSL Certificate..."

certbot --nginx \
-d $DOMAIN \
--non-interactive \
--agree-tos \
--no-eff-email \
-m $EMAIL \
--redirect

if [ $? -ne 0 ]; then
    echo "❌ SSL Gagal. Cek DNS / Port 80"
    exit 1
fi

echo ""
echo "========================================"
echo "      INSTALLATION COMPLETE ✅"
echo "========================================"
echo ""
echo "Panel URL: https://$DOMAIN"
echo "Login:"
echo "Email: $EMAIL"
echo "Password: $PASSWORD"
