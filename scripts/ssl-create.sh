#!/bin/bash

# Script para gerar certificados SSL com Let's Encrypt
# Uso: ./scripts/ssl-create.sh <php_version> <app_name> [email]

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

# Função de ajuda
show_help() {
    echo "🔒 Gerador de Certificados SSL - Let's Encrypt"
    echo "============================================="
    echo
    echo "📋 USO:"
    echo "  $0 <php_version> <app_name> [email]"
    echo
    echo "📝 PARÂMETROS:"
    echo "  php_version    Versão do PHP (php84, php74, php56)"
    echo "  app_name       Nome da aplicação"
    echo "  email          Email para Let's Encrypt (opcional)"
    echo
    echo "🎯 EXEMPLOS:"
    echo "  $0 php84 loja admin@empresa.com"
    echo "  $0 php74 blog"
    echo
    echo "⚠️  IMPORTANTE:"
    echo "  - O domínio deve estar apontando para este servidor"
    echo "  - A aplicação deve estar funcionando via HTTP primeiro"
    echo "  - Certificados são válidos por 90 dias (renovação automática)"
}

# Verificar argumentos
if [ $# -lt 2 ]; then
    error "Argumentos insuficientes"
    show_help
    exit 1
fi

PHP_VERSION="$1"
APP_NAME="$2"
EMAIL="${3:-admin@$(hostname -d 2>/dev/null || echo 'localhost')}"

# Validar versão do PHP
case "$PHP_VERSION" in
    php84|php74|php56)
        ;;
    *)
        error "Versão PHP inválida: $PHP_VERSION"
        echo "Versões suportadas: php84, php74, php56"
        exit 1
        ;;
esac

# Verificar se a aplicação existe
if [ ! -d "/sistemas/apps/$PHP_VERSION/$APP_NAME" ] && [ ! -d "./apps/$PHP_VERSION/$APP_NAME" ]; then
    error "Aplicação não encontrada: $PHP_VERSION/$APP_NAME"
    exit 1
fi

# Encontrar configuração Nginx da aplicação
NGINX_CONFIG=""
if [ -f "nginx/conf.d/app-$APP_NAME.conf" ]; then
    NGINX_CONFIG="nginx/conf.d/app-$APP_NAME.conf"
elif [ -f "nginx/conf.d/$APP_NAME.conf" ]; then
    NGINX_CONFIG="nginx/conf.d/$APP_NAME.conf"
else
    error "Configuração Nginx não encontrada para: $APP_NAME"
    exit 1
fi

# Extrair domínio da configuração Nginx
DOMAIN=$(grep -E "^\s*server_name\s+" "$NGINX_CONFIG" | head -1 | awk '{print $2}' | sed 's/;//')

if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "_" ]; then
    error "Domínio não encontrado na configuração Nginx"
    exit 1
fi

info "🔒 Gerando certificado SSL"
echo "================================"
info "PHP: $PHP_VERSION"
info "App: $APP_NAME"
info "Domínio: $DOMAIN"
info "Email: $EMAIL"
info "Config: $NGINX_CONFIG"
echo

# Verificar se domínio está acessível
info "🌐 Verificando acessibilidade do domínio..."
if ! curl -s -f -m 10 "http://$DOMAIN" >/dev/null 2>&1; then
    warning "⚠️  Domínio não acessível via HTTP: $DOMAIN"
    echo "Certifique-se de que:"
    echo "  1. O domínio aponta para este servidor"
    echo "  2. A aplicação está rodando via HTTP"
    echo "  3. As portas 80/443 estão abertas"
    echo
    read -p "Continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Operação cancelada"
        exit 1
    fi
fi

# Verificar se Certbot está rodando
info "🐳 Verificando container Certbot..."
if ! docker compose ps certbot | grep -q "Up"; then
    info "Iniciando container Certbot..."
    docker compose up -d certbot
    sleep 5
fi

# Criar diretórios necessários
info "📁 Criando estrutura de diretórios..."
mkdir -p nginx/ssl/letsencrypt
mkdir -p nginx/ssl/lib
mkdir -p nginx/ssl/www
mkdir -p nginx/ssl/live/$DOMAIN

# Configurar Nginx para validação ACME (webroot)
info "⚙️  Configurando Nginx para validação ACME..."

# Backup da configuração atual
cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup"

# Adicionar location para ACME challenge se não existir
if ! grep -q "\.well-known/acme-challenge" "$NGINX_CONFIG"; then
    # Adicionar antes da última chave }
    sed -i '/^}/i\
    # ACME Challenge para Let'\''s Encrypt\
    location /.well-known/acme-challenge/ {\
        root /var/www/certbot;\
    }\
' "$NGINX_CONFIG"
    
    info "📝 Configuração ACME adicionada ao Nginx"
    
    # Recarregar Nginx
    docker compose exec nginx nginx -s reload
    sleep 2
fi

# Gerar certificado
info "🔐 Gerando certificado com Let's Encrypt..."
echo "Este processo pode levar alguns minutos..."

if docker compose exec certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN"; then
    
    success "✅ Certificado gerado com sucesso!"
else
    error "❌ Falha ao gerar certificado"
    # Restaurar backup
    mv "${NGINX_CONFIG}.backup" "$NGINX_CONFIG"
    docker compose exec nginx nginx -s reload
    exit 1
fi

# Copiar certificados para localização do Nginx
info "📋 Copiando certificados para Nginx..."
docker compose exec certbot cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/etc/letsencrypt/live/$DOMAIN/cert.pem"
docker compose exec certbot cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "/etc/letsencrypt/live/$DOMAIN/key.pem"

# Criar links simbólicos para compatibilidade
docker compose exec nginx ln -sf "/etc/letsencrypt/live/$DOMAIN/cert.pem" "/etc/nginx/ssl/cert.pem" 2>/dev/null || true
docker compose exec nginx ln -sf "/etc/letsencrypt/live/$DOMAIN/key.pem" "/etc/nginx/ssl/key.pem" 2>/dev/null || true

# Atualizar configuração Nginx para HTTPS
info "🔧 Atualizando configuração para HTTPS..."

# Usar template HTTPS
HTTPS_TEMPLATE="nginx/templates/$PHP_VERSION-https-template.conf"
if [ ! -f "$HTTPS_TEMPLATE" ]; then
    error "Template HTTPS não encontrado: $HTTPS_TEMPLATE"
    mv "${NGINX_CONFIG}.backup" "$NGINX_CONFIG"
    exit 1
fi

# Gerar nova configuração baseada no template HTTPS
TEMP_CONFIG=$(mktemp)
sed -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{DOMAIN}}/$DOMAIN/g" \
    -e "s/{{PHP_VERSION}}/$PHP_VERSION/g" \
    "$HTTPS_TEMPLATE" > "$TEMP_CONFIG"

# Substituir configuração
mv "$TEMP_CONFIG" "$NGINX_CONFIG"

# Recarregar Nginx
info "🔄 Recarregando Nginx..."
if docker compose exec nginx nginx -t && docker compose exec nginx nginx -s reload; then
    success "✅ Nginx recarregado com sucesso!"
else
    error "❌ Erro na configuração Nginx, restaurando backup..."
    mv "${NGINX_CONFIG}.backup" "$NGINX_CONFIG"
    docker compose exec nginx nginx -s reload
    exit 1
fi

# Remover backup se tudo deu certo
rm -f "${NGINX_CONFIG}.backup"

# Testar HTTPS
info "🧪 Testando HTTPS..."
if curl -s -f -m 10 "https://$DOMAIN" >/dev/null 2>&1; then
    success "✅ HTTPS funcionando!"
else
    warning "⚠️  HTTPS pode não estar funcionando corretamente"
fi

echo
success "🎉 Certificado SSL configurado com sucesso!"
echo
info "📋 Informações do certificado:"
info "  Domínio: $DOMAIN"
info "  Aplicação: $PHP_VERSION/$APP_NAME"
info "  Localização: /etc/letsencrypt/live/$DOMAIN/"
info "  Validade: 90 dias"
echo
info "🔄 Renovação automática:"
info "  Execute: ./scripts/ssl-renew.sh"
info "  Ou configure cron para execução automática"
echo
info "🌐 URLs disponíveis:"
info "  HTTP: http://$DOMAIN (redireciona para HTTPS)"
info "  HTTPS: https://$DOMAIN"
