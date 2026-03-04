#!/bin/bash
set -euo pipefail

echo "===== PTERODACTYL AUTO INSTALLER v1.0 ====="

# -------------------------------
# CONFIGURABLE VARIABLES
# -------------------------------
read -p "Masukkan domain panel: " PANEL_DOMAIN
read -p "Masukkan domain node: " NODE_DOMAIN
read -sp "Masukkan password admin panel: " PANEL_ADMIN_PASSWORD
echo
read -p "Masukkan email admin (untuk SSL/notifications): " ADMIN_EMAIL

# -------------------------------
# STEP 1: Bersihkan VPS
# -------------------------------
echo "[1/7] Membersihkan sisa instalasi..."
sudo systemctl stop docker containerd || true
sudo docker ps -aq | xargs -r sudo docker rm -f || true
sudo docker images -aq | xargs -r sudo docker rmi -f || true
sudo apt remove --purge -y docker docker-engine docker.io containerd runc nginx mysql-server mysql-client || true
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /run/docker /var/lib/pterodactyl /var/lib/mysql /var/log/pterodactyl /var/log/mysql /var/cache/pterodactyl /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*
sudo rm -f /usr/bin/docker /usr/bin/dockerd /usr/bin/containerd /usr/bin/containerd-shim /usr/bin/runc
sudo systemctl daemon-reload
sudo systemctl reset-failed
echo "[OK] VPS bersih"

# -------------------------------
# STEP 2: Update & Install Dependencies
# -------------------------------
echo "[2/7] Update apt dan install dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget unzip tar git lsb-release gnupg apt-transport-https ca-certificates python3 python3-pip pwgen mariadb-client mariadb-server nginx certbot python3-certbot-nginx

# -------------------------------
# STEP 3: Database Setup
# -------------------------------
echo "[3/7] Setup MariaDB untuk Pterodactyl..."
sudo systemctl start mariadb
DB_EXISTS=$(sudo mysql -uroot -sse "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='pterodactyl';" || echo "")
if [ -n "$DB_EXISTS" ]; then
    echo "[!] Database 'pterodactyl' sudah ada, menghapus dulu..."
    sudo mysql -uroot -e "DROP DATABASE pterodactyl;"
    sudo mysql -uroot -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
fi
DB_PASS=$(pwgen 32 1)
sudo mysql -uroot -e "CREATE DATABASE pterodactyl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -uroot -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"
echo "[OK] Database siap"

# -------------------------------
# STEP 4: Install Panel
# -------------------------------
echo "[4/7] Install Pterodactyl Panel..."
cd /var/www/
sudo rm -rf pterodactyl
sudo git clone https://github.com/pterodactyl/panel.git pterodactyl
cd pterodactyl
sudo chmod -R 755 storage bootstrap/cache
sudo cp .env.example .env
sudo sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|g" .env
sudo php artisan key:generate --force

# -------------------------------
# STEP 5: Setup Nginx & SSL
# -------------------------------
echo "[5/7] Konfigurasi Nginx..."
cat <<EOF | sudo tee /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $PANEL_DOMAIN;

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/$PANEL_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$PANEL_DOMAIN/privkey.pem;

    client_max_body_size 100m;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
sudo nginx -t
sudo systemctl restart nginx
echo "[OK] Nginx & SSL siap"

# -------------------------------
# STEP 6: Certbot SSL
# -------------------------------
echo "[6/7] Mendapatkan SSL LetsEncrypt..."
sudo certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos -m $ADMIN_EMAIL

# -------------------------------
# STEP 7: Install Wings (Node)
# -------------------------------
echo "[7/7] Install Wings Node..."
curl -sSL https://get.pterodactyl.com/wings.sh | sudo bash -s -- --interactive=false --domain $NODE_DOMAIN

echo "[SUCCESS] Instalasi Panel & Wings selesai!"
echo "Panel: https://$PANEL_DOMAIN"
echo "Node: $NODE_DOMAIN"
echo "DB user: pterodactyl"
echo "DB password: $DB_PASS"
