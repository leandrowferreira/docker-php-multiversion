#!/bin/bash

# Script para criar uma nova aplicação no sistema
# Suporta domínios principais e subdomínios
# Uso: ./app-create.sh <versao-php> <nome-da-app> <dominio> [--www] [--subdomain]
# Exemplo: ./app-create.sh php84 minha-loja loja.exemplo.com --www

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0echo "🎉 Aplicação '$APP_NAME' criada com sucesso!"31m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Função para mostrar ajuda
show_help() {
    echo "🚀 Script para criar nova aplicação"
    echo "===================================="
    echo ""
    echo "Uso: $0 <versao-php> <nome-da-app> <dominio> [opções]"
    echo ""
    echo "Parâmetros:"
    echo "  versao-php     php84, php74 ou php56"
    echo "  nome-da-app    Nome da aplicação (sem espaços)"
    echo "  dominio        Domínio principal da aplicação"
    echo ""
    echo "Opções:"
    echo "  --www          Adicionar redirect www -> não-www"
    echo "  --subdomain    Tratar como subdomínio (app.exemplo.com)"
    echo "  --ssl          Configurar SSL/HTTPS (usar após configurar certificados)"
    echo "  --no-ssl       Forçar apenas HTTP (padrão)"
    echo "  --laravel      Configurar especificamente para Laravel"
    echo "  -h, --help     Mostrar esta ajuda"
    echo ""
    echo "⚠️  PADRÃO: Cria apenas HTTP. Use --ssl após configurar certificados."
    echo ""
    echo "Exemplos:"
    echo "  $0 php84 loja minhaloja.com --www           # HTTP com redirect www"
    echo "  $0 php74 blog blog.exemplo.com --subdomain  # HTTP simples"
    echo "  $0 php84 app app.com --ssl                   # HTTPS (certificados já configurados)"
    echo ""
}

# Variáveis padrão
APP_NAME=""
PHP_VERSION=""
DOMAIN=""
INCLUDE_WWW=false
IS_SUBDOMAIN=false
NO_SSL=true      # Padrão: apenas HTTP (SSL adicionado posteriormente)
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
        --ssl)
            NO_SSL=false
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
            if [ -z "$PHP_VERSION" ]; then
                PHP_VERSION="$1"
            elif [ -z "$APP_NAME" ]; then
                APP_NAME="$1"
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
if [ -z "$PHP_VERSION" ] || [ -z "$APP_NAME" ] || [ -z "$DOMAIN" ]; then
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

echo "🚀 Criando nova aplicação"
echo "========================="
info "PHP: $PHP_VERSION"
info "Nome: $APP_NAME"
info "Domínio: $DOMAIN"
info "Incluir www: $INCLUDE_WWW"
info "Subdomínio: $IS_SUBDOMAIN"
info "SSL: $([ "$NO_SSL" = true ] && echo "HTTP apenas (padrão)" || echo "HTTPS habilitado")"
info "Laravel: $IS_LARAVEL"
echo ""

# Função para criar arquivos diretamente no container em produção
create_files_in_production() {
    local php_version="$1"
    local app_name="$2"
    local app_dir="$3"
    
    if [ "$ENV_TYPE" = "produção" ]; then
        info "Criando estrutura Laravel diretamente no container..."
        
        local container_name="app-${php_version}"
        local container_path="/var/www/html/${php_version}/${app_name}"
        
        # Verificar se container está rodando
        if ! docker ps | grep -q "$container_name"; then
            error "Container $container_name não está rodando. Execute: scripts/start.sh"
            exit 1
        fi
        
        # Criar estrutura de diretórios no container
        docker exec "$container_name" mkdir -p "$container_path/public"
        docker exec "$container_name" mkdir -p "$container_path/storage/logs"
        docker exec "$container_name" mkdir -p "$container_path/storage/framework/cache"
        docker exec "$container_name" mkdir -p "$container_path/storage/framework/sessions"
        docker exec "$container_name" mkdir -p "$container_path/storage/framework/views"
        
        # Criar index.php básico
        docker exec "$container_name" bash -c "cat > '$container_path/public/index.php' << 'EOF'
<?php
// Aplicação Web - Placeholder
echo \"<h1>Aplicação em manutenção</h1>\";
echo \"<p>Esta aplicação será configurada em breve.</p>\";
echo \"<p>PHP Version: \" . phpversion() . \"</p>\";
echo \"<p>Servidor: \" . \$_SERVER['SERVER_NAME'] . \"</p>\";
EOF"
        
        # Criar .env exemplo
        docker exec "$container_name" bash -c "cat > '$container_path/.env.example' << 'EOF'
APP_NAME=\"Minha Aplicação\"
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
EOF"
        
        # Ajustar permissões
        docker exec "$container_name" chown -R www-data:www-data "$container_path"
        
        success "Estrutura criada diretamente no container"
        return 0
    fi
    
    return 1
}

# Detectar ambiente (desenvolvimento vs produção)
if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
    # Ambiente de desenvolvimento
    APP_DIR="./apps/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="desenvolvimento"
    info "Ambiente detectado: DESENVOLVIMENTO"
else
    # Ambiente de produção
    APP_DIR="/sistemas/apps/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="produção"
    info "Ambiente detectado: PRODUÇÃO"
fi

info "Criando diretório: $APP_DIR"

# Verificar se diretório base existe
if [ "$ENV_TYPE" = "produção" ] && [ ! -d "/sistemas" ]; then
    error "Diretório /sistemas não existe. Execute: scripts/start.sh"
    exit 1
elif [ "$ENV_TYPE" = "desenvolvimento" ] && [ ! -d "apps" ]; then
    error "Diretório ./apps não existe. Execute no diretório correto do projeto"
    exit 1
fi

# Criar diretório com permissões apropriadas
if [ "$ENV_TYPE" = "produção" ]; then
    sudo mkdir -p "$APP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR"
else
    mkdir -p "$APP_DIR"
fi
success "Diretório criado: $APP_DIR"

# Verificar se é uma estrutura Laravel existente
is_laravel_existing() {
    local app_dir="$1"
    
    # Verificar arquivos/diretórios essenciais do Laravel
    if [ -f "$app_dir/artisan" ] || \
       [ -f "$app_dir/composer.json" ] || \
       [ -d "$app_dir/app" ] || \
       [ -d "$app_dir/config" ] || \
       [ -d "$app_dir/routes" ] || \
       [ -f "$app_dir/public/index.php" ]; then
        return 0  # É Laravel existente
    else
        return 1  # Não é Laravel ou não existe
    fi
}

# Criar estrutura Laravel básica
if [ "$IS_LARAVEL" = true ]; then
    if [ "$ENV_TYPE" = "produção" ]; then
        # Em produção, criar diretamente no container
        create_files_in_production "$PHP_VERSION" "$APP_NAME" "$APP_DIR"
    else
        # Em desenvolvimento, verificar se já existe
        if is_laravel_existing "$APP_DIR"; then
            success "Estrutura Laravel já existe, mantendo arquivos existentes"
        else
            info "Criando estrutura Laravel básica..."
        
        mkdir -p "$APP_DIR/public"
        mkdir -p "$APP_DIR/storage/logs"
        mkdir -p "$APP_DIR/storage/framework/cache"
        mkdir -p "$APP_DIR/storage/framework/sessions"
        mkdir -p "$APP_DIR/storage/framework/views"
        
        # Criar index.php básico
        cat > "$APP_DIR/public/index.php" << 'EOF'
<?php
// Aplicação Web - Placeholder
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
    fi
fi

# Determinar configuração de domínios
DOMAINS="$DOMAIN"
if [ "$INCLUDE_WWW" = true ]; then
    DOMAINS="$DOMAIN www.$DOMAIN"
fi

# Definir caminhos baseado no ambiente
if [ "$ENV_TYPE" = "produção" ]; then
    NGINX_CONF="/sistemas/nginx/conf.d/app-$APP_NAME.conf"
    TEMPLATE_BASE="/sistemas/nginx/templates"
else
    NGINX_CONF="nginx/conf.d/app-$APP_NAME.conf"
    TEMPLATE_BASE="nginx/templates"
fi

# Escolher template baseado na configuração SSL
if [ "$NO_SSL" = true ]; then
    TEMPLATE_FILE="$TEMPLATE_BASE/$PHP_VERSION-http-template.conf"
else
    TEMPLATE_FILE="$TEMPLATE_BASE/$PHP_VERSION-https-template.conf"
fi

info "Criando configuração Nginx: $NGINX_CONF"
info "Usando template: $TEMPLATE_FILE"

# Verificar e criar diretórios necessários
if [ "$ENV_TYPE" = "produção" ]; then
    # Criar estrutura nginx em produção se não existir
    if [ ! -d "/sistemas/nginx" ]; then
        info "Criando estrutura nginx em produção..."
        sudo mkdir -p /sistemas/nginx/{conf.d,templates,ssl}
        sudo chown -R $USER:$USER /sistemas/nginx
        
        # Copiar templates se não existirem
        if [ -d "nginx/templates" ] && [ ! -d "/sistemas/nginx/templates" ]; then
            info "Copiando templates nginx..."
            sudo cp -r nginx/templates /sistemas/nginx/
            sudo chown -R $USER:$USER /sistemas/nginx/templates
        fi
    fi
    
    # Verificar se diretório conf.d existe
    if [ ! -d "/sistemas/nginx/conf.d" ]; then
        sudo mkdir -p /sistemas/nginx/conf.d
        sudo chown -R $USER:$USER /sistemas/nginx/conf.d
    fi
fi

# Verificar se o template existe
if [ ! -f "$TEMPLATE_FILE" ]; then
    error "Template não encontrado: $TEMPLATE_FILE"
    
    # Sugestão de solução baseada no ambiente
    if [ "$ENV_TYPE" = "produção" ]; then
        echo ""
        warning "Para resolver em produção:"
        echo "  1. Copie os templates: sudo cp -r nginx/templates /sistemas/nginx/"
        echo "  2. Execute novamente o comando"
    fi
    exit 1
fi

# Copiar template e fazer substituições
cp "$TEMPLATE_FILE" "$NGINX_CONF"

# Substituir variáveis no template
sed -i "s/{{APP_NAME}}/$APP_NAME/g" "$NGINX_CONF"
sed -i "s/{{DOMAIN}}/$DOMAIN/g" "$NGINX_CONF"
sed -i "s/{{PHP_VERSION}}/$PHP_VERSION/g" "$NGINX_CONF"

# Remover comentários do template (linhas que começam com ##)
sed -i '/^##/d' "$NGINX_CONF"

# Adicionar cabeçalho com informações da criação
sed -i "1i# Aplicação: $APP_NAME" "$NGINX_CONF"
sed -i "2i# Domínio: $DOMAIN" "$NGINX_CONF"
sed -i "3i# PHP: $PHP_VERSION" "$NGINX_CONF"
sed -i "4i# Gerado automaticamente em $(date)" "$NGINX_CONF"
sed -i "5i# Template: $TEMPLATE_FILE" "$NGINX_CONF"
sed -i "6i#" "$NGINX_CONF"

# Configurações específicas baseadas nas opções
if [ "$INCLUDE_WWW" = true ]; then
    # Adicionar redirecionamento www antes do primeiro server block
    if [ "$NO_SSL" = true ]; then
        WWW_REDIRECT="# Redirect www to non-www (HTTP)
server {
    listen 80;
    server_name www.$DOMAIN;
    return 301 http://$DOMAIN\$request_uri;
}

"
    else
        WWW_REDIRECT="# Redirect www to non-www
server {
    listen 80;
    server_name www.$DOMAIN;
    return 301 http://$DOMAIN\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.$DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
}

"
    fi
    
    # Inserir antes do primeiro server block ou comentário de configuração
    sed -i "/^# Configuração HTTP principal\|^# Redirect HTTP para HTTPS/i $WWW_REDIRECT" "$NGINX_CONF"
fi

success "Configuração Nginx criada"

# Recarregar configuração do Nginx
info "Recarregando Nginx..."
if docker ps | grep -q nginx-proxy; then
    docker exec nginx-proxy nginx -s reload
    success "Nginx recarregado"
else
    warning "Container nginx-proxy não está rodando"
    warning "Execute: docker-compose up -d nginx"
fi

echo ""
echo "�� Aplicação '$APP_NAME' adicionada com sucesso!"
echo ""
info "📋 Próximos passos:"
echo "   1. Coloque o código da aplicação em: $APP_DIR"
echo "   2. Configure o DNS para apontar $DOMAIN para o IP da EC2"

if [ "$INCLUDE_WWW" = true ]; then
    echo "   3. Configure também www.$DOMAIN para o IP da EC2"
fi

if [ "$NO_SSL" = true ]; then
    echo "   4. 🔒 Para adicionar SSL/HTTPS:"
    echo "      ./scripts/setup-ssl.sh $APP_NAME $DOMAINS"
    echo "      (Configurará Let's Encrypt automaticamente)"
else
    echo "   4. ✅ SSL já configurado - verifique certificados"
fi

if [ "$IS_LARAVEL" = true ]; then
    echo "   5. Configure o arquivo .env da aplicação"
    echo "   6. Execute as migrações Laravel:"
    echo "      docker exec app-$PHP_VERSION bash -c \"cd /var/www/html/$PHP_VERSION/$APP_NAME && php artisan migrate\""
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
