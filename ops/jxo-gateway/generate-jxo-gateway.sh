tee -a /root/jxo-deployments/ops/jxo-gateway/jxo-gateway.conf << END
server {
  listen 80 default_server;
  server_name _;

  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;
  server_name joshuaxong.me;

  ssl_certificate /etc/letsencrypt/live/joshuaxong.me/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/joshuaxong.me/privkey.pem;

  location / {
    proxy_pass $1;
  }
}

server {
  listen 443 ssl;
  server_name rammus.tech;

  ssl_certificate /etc/letsencrypt/live/rammus.tech/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/rammus.tech/privkey.pem;

  location / {
    proxy_pass https://localhost:8080/;
  }
}

server {
  listen 8000;

  location / {
    proxy_pass http://example.com;
    proxy_set_header Host example.com;
  }
}

server {
  listen 1337;

  location / {
    return 301 https://google.com;
  }
}
END