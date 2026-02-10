#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Error: Must run as root" 
   exit 1
fi

if [ ! -f .env ]; then
    echo "Error: .env missing"
    exit 1
fi

# Export all variables from .env for envsubst to use
set -a
source .env
set +a

echo ">>> Bootstrapping server for $DOMAIN (this may take a few minutes)"

# I System Updates
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get upgrade -yqq
apt-get install -yqq curl git ufw fail2ban python3-pip apt-transport-https ca-certificates software-properties-common gnupg gettext-base

# II Security
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$DEPLOY_USER"
    echo "$DEPLOY_USER:$DEPLOY_PASS_HASH" | chpasswd -e
    usermod -aG sudo "$DEPLOY_USER"
fi

# Apply SSH Config
cp configs/sshd_config /etc/ssh/sshd_config
systemctl restart sshd

# Apply UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

# Apply Fail2ban
cp configs/fail2ban.local /etc/fail2ban/jail.local
systemctl restart fail2ban

# III. Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -yqq docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

usermod -aG docker "$DEPLOY_USER"

# IV Deploy
mkdir -p /opt/app
cp -r app docker-compose.yml /opt/app/
chown -R "$DEPLOY_USER":"$DEPLOY_USER" /opt/app

cd /opt/app
# Pass the env vars explicitly to docker compose
PORT=$PORT NODE_EXPORTER_PORT=$NODE_EXPORTER_PORT docker compose up -d --build --remove-orphans

# V Nginx & SSL
apt-get install -yqq nginx certbot python3-certbot-nginx

# Substitute vars in config
envsubst '${DOMAIN} ${PORT} ${NODE_EXPORTER_PORT}' < ../configs/nginx.conf > "/etc/nginx/sites-available/$DOMAIN"
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx

if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
fi

echo ">>> Setup complete."