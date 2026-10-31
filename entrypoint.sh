#!/bin/sh
set -eu
: "${UUID:?UUID env required}"
: "${WS_PATH:?WS_PATH env required}"
PORT="${PORT:-8080}"
XRAY_PORT=10000
mkdir -p /run/nginx

cat > /tmp/xray.json <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": ${XRAY_PORT},
    "protocol": "vless",
    "settings": {"clients": [{"id": "${UUID}", "level": 0}], "decryption": "none"},
    "streamSettings": {"network": "ws", "security": "none", "wsSettings": {"path": "${WS_PATH}"}}
  }],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
JSON

cat > /tmp/nginx.conf <<NGINX
user nginx;
worker_processes 1;
error_log /dev/stderr warn;
pid /run/nginx/nginx.pid;
events { worker_connections 256; }
http {
  access_log /dev/stdout;
  server {
    listen ${PORT};
    location ${WS_PATH} {
      proxy_pass http://127.0.0.1:${XRAY_PORT};
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      proxy_read_timeout 86400s;
      proxy_send_timeout 86400s;
    }
    location / {
      access_log off;
      default_type text/plain;
      return 200 "ok\n";
    }
  }
}
NGINX

/usr/local/bin/xray/xray run -test -c /tmp/xray.json
nginx -t -c /tmp/nginx.conf
/usr/local/bin/xray/xray run -c /tmp/xray.json &
XPID=$!
trap 'kill $XPID' EXIT
nginx -c /tmp/nginx.conf -g 'daemon off;'
