#!/bin/bash

# Script para adicionar SSL/HTTPS a uma aplicação existente
# Uso: ./setup-ssl.sh <nome-da-app> <dominio> [email]
# Exemplo: ./setup-ssl.sh minha-loja loja.exemplo.com admin@exemplo.com

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
    echo "🔒 Script para adicionar SSL a aplicação existente"
    echo "=============================================="
    echo ""
    echo "Uso: $0 <nome-da-app> <dominio> [email]"
    echo ""
    echo "Parâmetros:"
    echo "  nome-da-app    Nome da aplicação (deve existir)"
    echo "  dominio        Domínio principal da aplicação"
    echo "  email          Email para Let's Encrypt (opcional)"
    echo ""
    echo "Exemplos:"
    echo "  $0 loja minhaloja.com admin@minhaloja.com"
    echo "  $0 blog blog.exemplo.com"
    echo ""
}

echo "🔒 Configuração SSL/HTTPS"
echo "========================"
echo ""
warning "SCRIPT EM DESENVOLVIMENTO"
echo ""
info "Este script irá:"
echo "   1. Verificar se a aplicação existe"
echo "   2. Gerar certificado Let's Encrypt"
echo "   3. Atualizar configuração Nginx para HTTPS"
echo "   4. Configurar redirecionamento HTTP → HTTPS"
echo ""
error "Funcionalidade ainda não implementada"
echo ""
info "Para implementar SSL manualmente:"
echo "   1. Configure Let's Encrypt:"
echo "      sudo certbot --nginx -d SEU_DOMINIO"
echo "   2. Ou use os templates HTTPS:"
echo "      ./scripts/add-app.sh nome php84 dominio.com --ssl"
echo ""
