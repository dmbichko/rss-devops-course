#!/bin/bash

# Update the system
apt-get update
apt-get upgrade -y

# Install Nginx
apt-get install -y nginx

# Create a reverse proxy configuration for Jenkins
cat << EOF > /etc/nginx/sites-available/jenkins
server {
    listen 8080;
    server_name _;

    location / {
        proxy_pass http://${jenkins_private_ip}:${jenkins_nodeport};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 80;
    server_name _;

    location / {
        proxy_pass http://${wordpress_private_ip}:${wordpess_nodeport};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the new site
ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Enable Nginx to start on boot
systemctl enable nginx
