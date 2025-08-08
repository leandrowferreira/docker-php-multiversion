#!/bin/bash

# Script para renovar certificados SSL Let's Encrypt
# Uso: ./scripts/ssl-renew.sh [domain]

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
    echo "🔄 Renovador de Certificados SSL"
    echo "==============================="
    echo
    echo "📋 USO:"
    echo "  $0 [domain]"
    echo
    echo "📝 PARÂMETROS:"
    echo "  domain    Domínio específico para renovar (opcional)"
    echo
    echo "🎯 EXEMPLOS:"
    echo "  $0                    # Renovar todos os certificados"
    echo "  $0 webhook-store.com  # Renovar certificado específico"
    echo
    echo "⚠️  IMPORTANTE:"
    echo "  - Certificados são renovados automaticamente quando têm menos de 30 dias"
    echo "  - Execute este script via cron para renovação automática"
}

SPECIFIC_DOMAIN="$1"

info "🔄 Renovando certificados SSL"
echo "============================="

# Verificar se Certbot está rodando
info "🐳 Verificando container Certbot..."
if ! docker compose ps certbot | grep -q "Up"; then
    info "Iniciando container Certbot..."
    docker compose up -d certbot
    sleep 5
fi

# Renovar certificados
if [ -n "$SPECIFIC_DOMAIN" ]; then
    info "🔐 Renovando certificado para: $SPECIFIC_DOMAIN"
    
    if docker compose exec certbot certbot renew --cert-name "$SPECIFIC_DOMAIN"; then
        success "✅ Certificado renovado: $SPECIFIC_DOMAIN"
    else
        error "❌ Falha ao renovar certificado: $SPECIFIC_DOMAIN"
        exit 1
    fi
else
    info "🔐 Renovando todos os certificados..."
    
    if docker compose exec certbot certbot renew; then
        success "✅ Renovação de certificados concluída"
    else
        error "❌ Falha na renovação de certificados"
        exit 1
    fi
fi

# Recarregar Nginx se houver certificados renovados
info "🔄 Recarregando Nginx..."
if docker compose exec nginx nginx -s reload; then
    success "✅ Nginx recarregado"
else
    warning "⚠️  Falha ao recarregar Nginx"
fi

# Listar certificados e validade
info "📋 Status dos certificados:"
docker compose exec certbot certbot certificates

echo
success "🎉 Renovação de certificados concluída!"
echo
info "📅 Próxima verificação recomendada em 30 dias"
info "🤖 Para automação, adicione ao cron:"
info "    0 12 * * * /caminho/para/scripts/ssl-renew.sh"
