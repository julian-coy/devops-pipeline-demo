#!/bin/bash
set -e

yum update -y
yum install -y nginx

cat > /usr/share/nginx/html/index.html << 'EOF'
${app_content}
EOF

systemctl start nginx
systemctl enable nginx
