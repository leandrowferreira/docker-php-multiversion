#!/bin/bash

# Script para adicionar uma nova aplicação ao sistema
# Suporta domínios principais e subdomínios
# Uso: ./add-app.sh <nome-da-app> <versao-php> <dominio> [--www] [--subdomain]
# Exemplo: ./add-app.sh minha-loja php84 loja.exemplo.com --www

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Função para mostrar ajuda
show_help() {
    echo "🚀 Script para adicionar nova aplicação"
    echo "======================================"
    echo ""
    echo "Uso: $0 <nome-da-app> <versao-php> <dominio> [opções]"
    echo ""
    echo "Parâmetros:"
    echo "  nome-da-app    Nome da aplicação (sem espaços)"
    echo "  versao-php     php84, php74 ou php56"
    echo "  dominio        Domínio principal da aplicação"
    echo ""
    echo "Opções:"
    echo "  --www          Adicionar redirect www -> não-www"
    echo "  --subdomain    Tratar como subdomínio (app.exemplo.com)"
    echo "  --no-ssl       Não configurar SSL (apenas HTTP)"
    echo "  --laravel      Configurar especificamente para Laravel"
    echo "  -h, --help     Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 loja php84 minhaloja.com --www"
    echo "  $0 blog php74 blog.exemplo.com --subdomain"
    echo "  $0 sistema-antigo php56 legado.cliente.com --laravel"
    echo ""
}

# Variáveis padrão
APP_NAME=""
PHP_VERSION=""
DOMAIN=""
INCLUDE_WWW=false
IS_SUBDOMAIN=false
NO_SSL=false
IS_LARAVEL=true  # Padrão para Laravel

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --www)
            INCLUDE_WWW=true
            shift
            ;;
        --subdomain)
            IS_SUBDOMAIN=true
            shift
            ;;
        --no-ssl)
            NO_SSL=true
            shift
            ;;
        --laravel)
            IS_LARAVEL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$APP_NAME" ]; then
                APP_NAME="$1"
            elif [ -z "$PHP_VERSION" ]; then
                PHP_VERSION="$1"
            elif [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            else
                error "Muitos argumentos"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validar argumentos obrigatórios
if [ -z "$APP_NAME" ] || [ -z "$PHP_VERSION" ] || [ -z "$DOMAIN" ]; then
    error "Argumentos obrigatórios não fornecidos"
    show_help
    exit 1
fi

# Validar versão do PHP
if [[ ! "$PHP_VERSION" =~ ^(php84|php74|php56)$ ]]; then
    error "Versão PHP inválida. Use: php84, php74 ou php56"
    exit 1
fi

# Validar nome da aplicação (sem espaços e caracteres especiais)
if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Nome da aplicação deve conter apenas letras, números, _ e -"
    exit 1
fi

echo "🚀 Adicionando nova aplicação"
echo "============================="
info "Nome: $APP_NAME"
info "PHP: $PHP_VERSION"
info "Domínio: $DOMAIN"
info "Incluir www: $INCLUDE_WWW"
info "Subdomínio: $IS_SUBDOMAIN"
info "SSL: $([ "$NO_SSL" = true ] && echo "Não" || echo "Sim")"
info "Laravel: $IS_LARAVEL"
echo ""

# Criar diretório da aplicação
APP_DIR="/sistemas/apps/$PHP_VERSION/$APP_NAME"
info "Criando diretório: $APP_DIR"

if [ ! -d "/sistemas" ]; then
    error "Diretório /sistemas não existe. Execute: scripts/setup-directories.sh"
    exit 1
fi

sudo mkdir -p "$APP_DIR"
sudo chown -R $USER:$USER "$APP_DIR"
success "Diretório criado: $APP_DIR"

# Criar estrutura Laravel básica se não existir
if [ "$IS_LARAVEL" = true ] && [ ! -f "$APP_DIR/public/index.php" ]; then
    info "Criando estrutura Laravel básica..."
    
    mkdir -p "$APP_DIR/public"
    mkdir -p "$APP_DIR/storage/logs"
    mkdir -p "$APP_DIR/storage/framework/cache"
    mkdir -p "$APP_DIR/storage/framework/sessions"
    mkdir -p "$APP_DIR/storage/framework/views"
    
    # Criar index.php básico
    cat > "$APP_DIR/public/index.php" << 'EOF'
<?php
// Aplicação Laravel - Placeholder
echo "<h1>Aplicação em manutenção</h1>";
echo "<p>Esta aplicação será configurada em breve.</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Servidor: " . $_SERVER['SERVER_NAME'] . "</p>";
EOF

    # Criar .env exemplo
    cat > "$APP_DIR/.env.example" << 'EOF'
APP_NAME="Minha Aplicação"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://SEU_DOMINIO

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mysql8
DB_PORT=3306
DB_DATABASE=sua_database
DB_USERNAME=sistemas_user
DB_PASSWORD=sistemas_pass

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
EOF

    success "Estrutura Laravel criada"
fi

# Determinar configuração de domínios
DOMAINS="$DOMAIN"
if [ "$INCLUDE_WWW" = true ]; then
    DOMAINS="$DOMAIN www.$DOMAIN"
fi

# Criar configuração do Nginx
NGINX_CONF="nginx/conf.d/app-$APP_NAME.conf"
info "Criando configuração Nginx: $NGINX_CONF"

# Configuração HTTP (sempre necessária para Let's Encrypt)
cat > "$NGINX_CONF" << EOF
# $APP_NAME - $DOMAIN
# Gerado automaticamente em $(date)

EOF

# Adicionar redirecionamento www se necessário
if [ "$INCLUDE_WWW" = true ]; then
    cat >> "$NGINX_CONF" << EOF
# Redirect www to non-www
server {
    listen 80;
    server_name www.$DOMAIN;
    return 301 http://$DOMAIN\$request_uri;
}

EOF

    if [ "$NO_SSL" = false ]; then
        cat >> "$NGINX_CONF" << EOF
server {
    listen 443 ssl http2;
    server_name www.$DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
    
    # SSL Configuration (será configurado pelo Let's Encrypt)
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
}

EOF
    fi
fi

# Servidor principal HTTP
cat >> "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN;
EOF

if [ "$NO_SSL" = false ]; then
    cat >> "$NGINX_CONF" << EOF
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
EOF
fi

# Configuração principal do servidor
cat >> "$NGINX_CONF" << EOF
    
    root /var/www/html/$PHP_VERSION/$APP_NAME/public;
    index index.php index.html index.htm;

    # SSL Configuration (será atualizada pelo Let's Encrypt)
EOF

if [ "$NO_SSL" = false ]; then
    cat >> "$NGINX_CONF" << EOF
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
EOF
fi

cat >> "$NGINX_CONF" << EOF

    # Rate limiting
    limit_req zone=login burst=20 nodelay;

    # Laravel specific configuration
EOF

if [ "$IS_LARAVEL" = true ]; then
    cat >> "$NGINX_CONF" << EOF
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
EOF
else
    cat >> "$NGINX_CONF" << EOF
    location / {
        try_files \$uri \$uri/ =404;
    }
EOF
fi

cat >> "$NGINX_CONF" << EOF

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass laravel-$PHP_VERSION:9000;
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
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|woff|woff2|ttf|svg)\$ {
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

EOF

if [ "$IS_LARAVEL" = true ]; then
    cat >> "$NGINX_CONF" << EOF
    # Laravel specific
    location ~ ^/(storage|bootstrap/cache)/ {
        deny all;
    }
EOF
fi

cat >> "$NGINX_CONF" << EOF
}
EOF

success "Configuração Nginx criada"
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

success "Configuração Nginx criada"

# Recarregar configuração do Nginx
info "Recarregando Nginx..."
if docker ps | grep -q nginx-proxy; then
    if docker exec nginx-proxy nginx -t; then
        docker exec nginx-proxy nginx -s reload
        success "Nginx recarregado com sucesso"
    else
        error "Erro na configuração do Nginx"
        warning "Verifique o arquivo: $NGINX_CONF"
        exit 1
    fi
else
    warning "Container nginx-proxy não está rodando"
    warning "Execute: docker-compose up -d nginx"
fi

echo ""
echo "🎉 Aplicação '$APP_NAME' adicionada com sucesso!"
echo ""
info "📋 Próximos passos:"
echo "   1. Coloque o código da aplicação em: $APP_DIR"
echo "   2. Configure o DNS para apontar $DOMAIN para o IP da EC2"

if [ "$INCLUDE_WWW" = true ]; then
    echo "   3. Configure também www.$DOMAIN para o IP da EC2"
fi

if [ "$NO_SSL" = false ]; then
    echo "   4. Configure SSL com Let's Encrypt:"
    echo "      ./scripts/setup-letsencrypt.sh -e seu@email.com $DOMAINS"
fi

if [ "$IS_LARAVEL" = true ]; then
    echo "   5. Configure o arquivo .env da aplicação"
    echo "   6. Execute as migrações Laravel:"
    echo "      docker exec laravel-$PHP_VERSION bash -c \"cd /var/www/html/$PHP_VERSION/$APP_NAME && php artisan migrate\""
fi

echo ""
info "🔍 Arquivos criados:"
echo "   - Configuração Nginx: $NGINX_CONF"
echo "   - Diretório da app: $APP_DIR"
if [ "$IS_LARAVEL" = true ]; then
    echo "   - Estrutura Laravel: $APP_DIR/public/"
    echo "   - Arquivo .env exemplo: $APP_DIR/.env.example"
fi

echo ""
success "✅ Aplicação pronta para receber código!"
