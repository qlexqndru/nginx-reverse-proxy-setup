#!/bin/bash

# Variables
DOMAIN_NAME="your_domain.com"  # Replace with your actual domain name
BACKEND_IP="backend_server_ip"  # Replace with the actual IP of your MyBB backend server
EMAIL_FOR_LETSENCRYPT="your-email@example.com"  # Replace with your email for Let's Encrypt notifications

# Nginx Paths
NGINX_AVAILABLE_VHOST="/etc/nginx/sites-available/$DOMAIN_NAME"
NGINX_ENABLED_VHOST="/etc/nginx/sites-enabled/$DOMAIN_NAME"
NGINX_BACKUP_DIR="/etc/nginx/backup-$(date +%F_%T)"
LETSENCRYPT_LIVE_PATH="/etc/letsencrypt/live/$DOMAIN_NAME"

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Backup existing Nginx configuration
echo "Backing up existing Nginx configuration..."
mkdir -p "$NGINX_BACKUP_DIR"
cp -r /etc/nginx/* "$NGINX_BACKUP_DIR"

# Install Nginx and Certbot if not already installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    apt update && apt install nginx -y || { echo "Failed to install Nginx"; exit 1; }
fi

if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    apt update && apt install certbot python3-certbot-nginx -y || { echo "Failed to install Certbot"; exit 1; }
fi

# Check if SSL certificate already exists, if not, obtain one
if [ ! -d "$LETSENCRYPT_LIVE_PATH" ]; then
    echo "Obtaining SSL certificate for $DOMAIN_NAME..."
    certbot --nginx -m "$EMAIL_FOR_LETSENCRYPT" --agree-tos --no-eff-email --redirect --hsts --staple-ocsp --domain "$DOMAIN_NAME" --keep-until-expiring || { echo "Failed to obtain SSL certificate"; exit 1; }
fi

# Generate strong Diffie-Hellman group if not already generated
if [ ! -f /etc/nginx/dhparam.pem ]; then
    echo "Generating strong Diffie-Hellman group..."
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 || { echo "Failed to generate Diffie-Hellman group"; exit 1; }
fi

# Create or overwrite Nginx server block configuration
echo "Configuring Nginx as a secure reverse proxy..."
cat > "$NGINX_AVAILABLE_VHOST" <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    ssl_certificate $LETSENCRYPT_LIVE_PATH/fullchain.pem;
    ssl_certificate_key $LETSENCRYPT_LIVE_PATH/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=300s;
    resolver_timeout 5s;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; object-src 'none';";

    location / {
        proxy_pass http://$BACKEND_IP;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Ensure the site is enabled by creating a symbolic link if not already exists
if [ ! -L "$NGINX_ENABLED_VHOST" ]; then
    ln -s "$NGINX_AVAILABLE_VHOST" "$NGINX_ENABLED_VHOST"
fi

# Test Nginx configuration and reload if successful
nginx -t && systemctl reload nginx || { echo "Nginx configuration test failed"; exit 1; }

echo "Nginx has been configured as a secure reverse proxy for $DOMAIN_NAME"
