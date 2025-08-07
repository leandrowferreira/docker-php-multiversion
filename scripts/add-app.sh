#!/bin/bash

# Script para adicionar uma nova aplicação ao sistema
# Uso: ./add-app.sh <nome-da-app> <versao-php> <dominio>
# Exemplo: ./add-app.sh minha-loja php81 loja.exemplo.com

set -e

if [ $# -ne 3 ]; then
    echo "❌ Uso: $0 <nome-da-app> <versao-php> <dominio>"
    echo "   Versões PHP disponíveis: php81, php74, php56"
    echo "   Exemplo: $0 minha-loja php81 loja.exemplo.com"
    exit 1
fi

APP_NAME=$1
PHP_VERSION=$2
DOMAIN=$3

# Validar versão do PHP
if [[ ! "$PHP_VERSION" =~ ^(php81|php74|php56)$ ]]; then
    echo "❌ Versão PHP inválida. Use: php81, php74 ou php56"
    exit 1
fi

echo "🚀 Adicionando nova aplicação: $APP_NAME"
echo "   Versão PHP: $PHP_VERSION"
echo "   Domínio: $DOMAIN"

# Criar diretório da aplicação
APP_DIR="/sistemas/apps/$PHP_VERSION/$APP_NAME"
sudo mkdir -p "$APP_DIR"
sudo chown -R $USER:$USER "$APP_DIR"

echo "📁 Diretório criado: $APP_DIR"

# Criar configuração do Nginx
NGINX_CONF="nginx/conf.d/app-$APP_NAME.conf"

cat > "$NGINX_CONF" << EOF
# $APP_NAME - $DOMAIN
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    root /var/www/html/$PHP_VERSION/$APP_NAME/public;
    index index.php index.html index.htm;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Rate limiting
    limit_req zone=login burst=20 nodelay;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app-$PHP_VERSION:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        
        # Timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        
        # Buffer settings
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(env|git) {
        deny all;
    }

    # Laravel specific
    location ~ ^/(storage|bootstrap/cache)/ {
        deny all;
    }
}
EOF

echo "⚙️  Configuração Nginx criada: $NGINX_CONF"

# Recarregar Nginx
if docker ps | grep -q nginx-proxy; then
    echo "🔄 Recarregando configuração do Nginx..."
    docker exec nginx-proxy nginx -s reload
    echo "✅ Nginx recarregado com sucesso!"
else
    echo "⚠️  Container nginx-proxy não está rodando. Execute 'docker-compose up -d' para iniciar."
fi

echo ""
echo "✅ Aplicação $APP_NAME adicionada com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Coloque o código da aplicação em: $APP_DIR"
echo "   2. Configure o DNS para apontar $DOMAIN para seu servidor"
echo "   3. Se necessário, ajuste as configurações em: $NGINX_CONF"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: docker-compose logs app-$PHP_VERSION"
echo "   Entrar no container: docker exec -it laravel-$PHP_VERSION bash"
