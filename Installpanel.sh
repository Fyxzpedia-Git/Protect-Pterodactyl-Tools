#!/bin/bash
set -e

# =========================
# PTERODACTYL + WINGS INSTALLER
# =========================

# ---------- CONFIGURATION ----------
read -p "Masukkan IP VPS: " VPS_IP
read -p "Masukkan Password root/MySQL: " MYSQL_PASS
read -p "Masukkan Domain Panel (contoh: panel.domain.com): " PANEL_DOMAIN
read -p "Masukkan Domain Node (contoh: node.domain.com): " NODE_DOMAIN

# ---------- CLEANUP PREVIOUS INSTALL ----------
echo "[1/10] Membersihkan sisa installasi lama..."
sudo systemctl stop docker containerd nginx mysql 2>/dev/null || true
sudo docker ps -aq 2>/dev/null | xargs -r sudo docker rm -f || true
sudo docker images -aq 2>/dev/null | xargs -r sudo docker rmi -f || true
sudo apt remove --purge -y docker docker-engine docker.io containerd runc nginx mysql-server mysql-client php* 2>/dev/null || true
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /run/docker /var/lib/pterodactyl /var/lib/mysql /var/log/pterodactyl /var/log/mysql /var/cache/pterodactyl /var/www/pterodactyl /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-available/pterodactyl.conf
sudo rm -f /usr/bin/docker /usr/bin/dockerd /usr/bin/containerd /usr/bin/containerd-shim /usr/bin/runc
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Bersihkan ld.so.preload
if grep -q "libprocesshider.so" /etc/ld.so.preload 2>/dev/null; then
    echo "[*] Membersihkan ld.so.preload..."
    sudo sed -i '/libprocesshider.so/d' /etc/ld.so.preload
fi

# ---------- UPDATE SYSTEM ----------
echo "[2/10] Update package list..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget unzip tar git lsb-release apt-transport-https ca-certificates gnupg lsof ufw fail2ban

# ---------- INSTALL PHP, MYSQL, NGINX ----------
echo "[3/10] Install dependencies Pterodactyl..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y
sudo apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-gd php8.3-curl php8.3-xml php8.3-zip nginx mariadb-server mariadb-client redis-server composer unzip tar

# ---------- CONFIGURE MYSQL ----------
echo "[4/10] Konfigurasi database..."
sudo systemctl start mariadb
sudo mysql -e "DROP DATABASE IF EXISTS pterodactyl;"
sudo mysql -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
sudo mysql -e "CREATE DATABASE pterodactyl;"
sudo mysql -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$MYSQL_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'127.0.0.1';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ---------- DOWNLOAD PTERODACTYL PANEL ----------
echo "[5/10] Download Pterodactyl Panel..."
cd /var/www
sudo git clone https://github.com/pterodactyl/panel.git pterodactyl || true
cd pterodactyl
sudo git reset --hard
sudo composer install --no-dev --optimize-autoloader
sudo cp .env.example .env
sudo php artisan key:generate
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo chmod -R 755 /var/www/pterodactyl

# ---------- NGINX CONFIG ----------
echo "[6/10] Konfigurasi nginx..."
sudo tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
sudo nginx -t
sudo systemctl restart nginx

# ---------- CERTBOT LETSENCRYPT ----------
echo "[7/10] Memasang SSL (Let's Encrypt)..."
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos -m admin@$PANEL_DOMAIN --redirect || true

# ---------- PANEL DATABASE MIGRATION ----------
echo "[8/10] Migrasi database dan seed..."
cd /var/www/pterodactyl
sudo php artisan migrate --seed --force

# ---------- INSTALL WINGS ----------
echo "[9/10] Install Wings (Node)..."
curl -Lo /tmp/wings.sh https://raw.githubusercontent.com/pterodactyl/wings/master/install.sh
chmod +x /tmp/wings.sh
# Jalankan Wings installer otomatis
sudo bash /tmp/wings.sh <<EOL
$NODE_DOMAIN
Y
Y
Y
EOL

# ---------- FINAL PERMISSIONS ----------
echo "[10/10] Set permission dan restart services..."
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo chmod -R 755 /var/www/pterodactyl
sudo systemctl restart nginx
sudo systemctl restart php8.3-fpm
sudo systemctl enable wings

echo "=================================="
echo "PTERODACTYL PANEL & WINGS INSTALLATION COMPLETE!"
echo "Panel: https://$PANEL_DOMAIN"
echo "Node: $NODE_DOMAIN"
echo "Database user: pterodactyl / $MYSQL_PASS"
echo "=================================="
