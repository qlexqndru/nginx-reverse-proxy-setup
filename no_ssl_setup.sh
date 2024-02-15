#!/bin/bash

# Variables
DOMAIN_NAME="your_domain.com"  # Replace with your actual domain name
BACKEND_IP="backend_server_ip"  # Replace with the actual IP of your MyBB backend server

# Nginx Paths
NGINX_AVAILABLE_VHOST="/etc/nginx/sites-available/$DOMAIN_NAME"
NGINX_ENABLED_VHOST="/etc/nginx/sites-enabled/$DOMAIN_NAME"

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Backup existing Nginx configuration (optional but recommended)
echo "Backing up existing Nginx configuration..."
mkdir -p "/etc/nginx/backup-$(date +%F_%T)"
cp -r /etc/nginx/* "/etc/nginx/backup-$(date +%F_%T)"

# Install Nginx if not already installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    apt update && apt install nginx -y || { echo "Failed to install Nginx"; exit 1; }
fi

# Create Nginx server block configuration for HTTP only
echo "Configuring Nginx as a reverse proxy..."
cat > "$NGINX_AVAILABLE_VHOST" <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

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

echo "Nginx has been configured as a reverse proxy for $DOMAIN_NAME"
