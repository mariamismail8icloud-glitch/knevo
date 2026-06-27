#!/usr/bin/env bash
#
# Knevo droplet provisioning — run ONCE on the server as root.
# Idempotent: safe to re-run. Sets up Postgres, JDK, nginx, TLS, ufw, swap,
# the systemd service, and secrets. Does NOT deploy app artifacts (that's
# build-and-push.sh + deploy.sh).
#
#   scp deploy/server-setup.sh root@<ip>:/root/ && ssh root@<ip> 'bash /root/server-setup.sh'
#
set -euo pipefail

DOMAIN="knevo.appscorner.com"
LE_EMAIL="moragab@gmail.com"
APP_DIR="/opt/knevo"
WEB_ROOT="/var/www/knevo"
ENV_FILE="/etc/knevo/knevo.env"

echo "==> [1/9] apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y postgresql nginx certbot python3-certbot-nginx \
  openjdk-21-jre-headless ufw curl rsync gzip

echo "==> [2/9] swap (2G)"
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> [3/9] app user + directories"
id -u knevo >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin knevo
mkdir -p "$APP_DIR/incoming" "$APP_DIR/backups" "$WEB_ROOT" /etc/knevo
chown -R knevo:knevo "$APP_DIR"

echo "==> [4/9] secrets ($ENV_FILE)"
if [ ! -f "$ENV_FILE" ]; then
  DB_PW="$(openssl rand -hex 24)"
  JWT="$(openssl rand -hex 48)"
  cat > "$ENV_FILE" <<EOF
DB_URL=jdbc:postgresql://localhost:5432/knevo?stringtype=unspecified
DB_USER=knevo
DB_PASSWORD=$DB_PW
JWT_SECRET=$JWT
SERVER_ADDRESS=127.0.0.1
SERVER_PORT=8080
EOF
  echo "    generated new secrets"
else
  echo "    keeping existing secrets"
fi
chmod 600 "$ENV_FILE"
set -a; . "$ENV_FILE"; set +a

echo "==> [5/9] postgres role + database"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='knevo'" | grep -q 1 \
  || sudo -u postgres psql -qc "CREATE ROLE knevo LOGIN PASSWORD '$DB_PASSWORD'"
sudo -u postgres psql -qc "ALTER ROLE knevo WITH PASSWORD '$DB_PASSWORD'"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='knevo'" | grep -q 1 \
  || sudo -u postgres psql -qc "CREATE DATABASE knevo OWNER knevo"

echo "==> [6/9] systemd service"
cat > /etc/systemd/system/knevo-backend.service <<'UNIT'
[Unit]
Description=Knevo backend (Spring Boot)
After=network.target postgresql.service
Wants=postgresql.service

[Service]
User=knevo
Group=knevo
WorkingDirectory=/opt/knevo
EnvironmentFile=/etc/knevo/knevo.env
ExecStart=/usr/bin/java -Xmx768m -jar /opt/knevo/knevo-backend.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable knevo-backend >/dev/null 2>&1 || true

echo "==> [7/9] nginx site"
[ -f "$WEB_ROOT/index.html" ] || echo '<h1>Knevo — provisioning</h1>' > "$WEB_ROOT/index.html"
cat > /etc/nginx/sites-available/knevo <<'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name knevo.appscorner.com;

    root /var/www/knevo;
    index index.html;

    client_max_body_size 12m;

    # SPA static files, fall back to index.html for client routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API -> Spring backend (preserves the /api prefix)
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/knevo /etc/nginx/sites-enabled/knevo
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "==> [8/9] ufw (SSH + web only)"
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

echo "==> [9/9] TLS via Let's Encrypt"
if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$LE_EMAIL" --redirect; then
  echo "    cert issued + http->https redirect on"
else
  echo "    WARN: certbot failed — site is up on http://$DOMAIN; re-run:"
  echo "      certbot --nginx -d $DOMAIN --agree-tos -m $LE_EMAIL --redirect"
fi

echo "==> server-setup complete. Now run deploy/build-and-push.sh from your Mac."
