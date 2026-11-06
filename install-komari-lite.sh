
#!/bin/bash

set -Eeuo pipefail

=========================================================

Komari Lite + Nginx HTTPS 自动部署

Debian / Ubuntu

=========================================================

DOMAIN="vps.699929.xyz"
SERVER_IP="177.201.225.58"
PORT="27777"

LITE_URL="https://raw.githubusercontent.com/nuomiiiii/lite/main/install-lite.sh"

NGINX_CONF="/etc/nginx/sites-available/komari-lite"
NGINX_LINK="/etc/nginx/sites-enabled/komari-lite"

if [ "$(id -u)" -ne 0 ]; then
echo "请使用 root 权限运行"
exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
echo "仅支持 Debian / Ubuntu"
exit 1
fi

echo "========================================"
echo "      Komari Lite 自动部署"
echo "========================================"
echo "服务器 IP：$SERVER_IP"
echo "域名：$DOMAIN"
echo "端口：$PORT"
echo "========================================"

read -rp "请输入 HTTPS 证书申请邮箱: " EMAIL

if [[ ! "$EMAIL" =~ ^[^@]+@[^@]+.[^@]+$ ]]; then
echo "邮箱格式错误"
exit 1
fi

安装依赖

apt-get update

apt-get install -y 
curl 
nginx 
certbot 
python3-certbot-nginx 
ca-certificates

安装 Komari Lite

echo "正在安装 Komari Lite..."

TMP_SCRIPT="$(mktemp)"

trap 'rm -f "$TMP_SCRIPT"' EXIT

curl -fsSL "$LITE_URL" -o "$TMP_SCRIPT"

bash "$TMP_SCRIPT"

Nginx WebSocket 配置

cat > /etc/nginx/conf.d/komari-lite-websocket.conf <<'EOF'
map $http_upgrade $connection_upgrade {
default upgrade;
''      close;
}
EOF

Nginx 反向代理

cat > "$NGINX_CONF" <<EOF
server {
listen 80;
listen [::]:80;

server_name $DOMAIN;

client_max_body_size 100M;

location / {
    proxy_pass http://127.0.0.1:$PORT;

    proxy_http_version 1.1;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;

    proxy_buffering off;

    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
}

}
EOF

启用站点

ln -sfn "$NGINX_CONF" "$NGINX_LINK"

nginx -t

systemctl enable nginx
systemctl restart nginx

申请 HTTPS

certbot --nginx 
-d "$DOMAIN" 
--email "$EMAIL" 
--agree-tos 
--non-interactive 
--redirect

自动续期

systemctl enable certbot.timer || true
systemctl start certbot.timer || true

检查

nginx -t

systemctl reload nginx

echo ""
echo "========================================"
echo "Komari Lite 部署完成"
echo "========================================"
echo ""
echo "访问地址：https://$DOMAIN"
echo "服务器 IP：$SERVER_IP"
echo "监听端口：$PORT"
echo ""
echo "检查 Nginx："
systemctl status nginx --no-pager
echo ""
echo "检查端口："
ss -lntp | grep "$PORT" || true
echo ""
echo "检查 HTTPS："
certbot certificates
