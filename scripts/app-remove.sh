#!/bin/bash

# Script para remover uma aplicação do sistema
# Uso: ./app-remove.sh <versao-php> <nome-da-app> [--force] [--delete-data]
# Exemplo: ./app-remove.sh php84 teste3 --force

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
    echo "🗑️  Script para remover aplicação"
    echo "=================================="
    echo ""
    echo "Uso: $0 <versao-php> <nome-da-app> [opções]"
    echo ""
    echo "Parâmetros:"
    echo "  versao-php     php84, php74 ou php56"
    echo "  nome-da-app    Nome da aplicação a ser removida"
    echo ""
    echo "Opções:"
    echo "  --force        Não pedir confirmação"
    echo "  --delete-data  Remover também os arquivos da aplicação"
    echo "  -h, --help     Mostrar esta ajuda"
    echo ""
    echo "⚠️  PADRÃO: Mantém os dados da aplicação (apenas remove config Nginx)"
    echo ""
    echo "Exemplos:"
    echo "  $0 php84 teste3                     # Remove config, mantém dados"
    echo "  $0 php84 teste3 --force             # Remove config sem confirmar"
    echo "  $0 php84 teste3 --delete-data       # Remove TUDO (config + dados)"
    echo "  $0 php84 teste3 --delete-data --force # Remove tudo sem confirmar"
    echo ""
}

# Variáveis padrão
PHP_VERSION=""
APP_NAME=""
FORCE=false
KEEP_DATA=true  # PADRÃO: Manter dados

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --delete-data)
            KEEP_DATA=false
            shift
            ;;
        --keep-data)
            # Manter compatibilidade, mas já é o padrão
            KEEP_DATA=true
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
if [ -z "$PHP_VERSION" ] || [ -z "$APP_NAME" ]; then
    error "Argumentos obrigatórios não fornecidos"
    show_help
    exit 1
fi

# Validar versão do PHP
if [[ ! "$PHP_VERSION" =~ ^(php84|php74|php56)$ ]]; then
    error "Versão PHP inválida. Use: php84, php74 ou php56"
    exit 1
fi

# Validar nome da aplicação
if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Nome da aplicação deve conter apenas letras, números, _ e -"
    exit 1
fi

echo "🗑️  Removendo aplicação"
echo "======================"
info "PHP: $PHP_VERSION"
info "Nome: $APP_NAME"
info "Forçar: $FORCE"
info "Manter dados: $([ "$KEEP_DATA" = true ] && echo "SIM (padrão)" || echo "NÃO (--delete-data)")"
echo ""

# Detectar ambiente (desenvolvimento vs produção)
if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
    # Ambiente de desenvolvimento
    APP_DIR="./apps/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="desenvolvimento"
    info "Ambiente detectado: DESENVOLVIMENTO"
    NGINX_BASE="nginx/conf.d"
else
    # Ambiente de produção
    APP_DIR="/sistemas/apps/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="produção"
    NGINX_BASE="/sistemas/nginx/conf.d"
    info "Ambiente detectado: PRODUÇÃO"
fi

# Configuração Nginx baseada no ambiente
NGINX_CONF="$NGINX_BASE/app-$APP_NAME.conf"

# Verificar se a aplicação existe
if [ ! -d "$APP_DIR" ] && [ ! -f "$NGINX_CONF" ]; then
    error "Aplicação '$APP_NAME' não encontrada!"
    echo "   Diretório: $APP_DIR"
    echo "   Config Nginx: $NGINX_CONF"
    exit 1
fi

# Mostrar o que será removido
echo "📋 Itens que serão removidos:"
if [ -f "$NGINX_CONF" ]; then
    echo "   ✓ Configuração Nginx: $NGINX_CONF"
fi
if [ -d "$APP_DIR" ] && [ "$KEEP_DATA" = false ]; then
    echo "   ✓ Diretório da aplicação: $APP_DIR"
    echo "   ✓ Todos os arquivos da aplicação"
    warning "ATENÇÃO: Os dados da aplicação serão REMOVIDOS!"
fi
if [ "$KEEP_DATA" = true ]; then
    success "Dados da aplicação serão MANTIDOS (padrão seguro)"
    echo "   📁 Diretório mantido: $APP_DIR"
fi

echo ""

# Confirmação (se não forçado)
if [ "$FORCE" = false ]; then
    if [ "$KEEP_DATA" = false ]; then
        echo "⚠️  ATENÇÃO: Esta ação removerá TODOS os arquivos da aplicação!"
        echo "   Esta ação não pode ser desfeita!"
    else
        echo "ℹ️  Operação segura: Apenas configuração Nginx será removida"
        echo "   Os dados da aplicação serão mantidos"
    fi
    echo ""
    read -p "Confirma a remoção da aplicação '$APP_NAME'? (y/N): " confirm
    case $confirm in
        [Yy]*) 
            info "Confirmado pelo usuário"
            ;;
        *) 
            info "Operação cancelada pelo usuário"
            exit 0
            ;;
    esac
fi

echo ""
info "Iniciando remoção..."

# 1. Remover configuração Nginx
if [ -f "$NGINX_CONF" ]; then
    rm -f "$NGINX_CONF"
    success "Configuração Nginx removida: $NGINX_CONF"
else
    warning "Configuração Nginx não encontrada: $NGINX_CONF"
fi

# 2. Recarregar Nginx
info "Recarregando Nginx..."
if docker ps | grep -q nginx-proxy; then
    docker exec nginx-proxy nginx -s reload
    success "Nginx recarregado"
else
    warning "Container nginx-proxy não está rodando"
fi

# 3. Remover diretório da aplicação (se não for para manter)
if [ "$KEEP_DATA" = false ] && [ -d "$APP_DIR" ]; then
    if [ "$ENV_TYPE" = "produção" ]; then
        sudo rm -rf "$APP_DIR"
    else
        rm -rf "$APP_DIR"
    fi
    success "Diretório da aplicação removido: $APP_DIR"
elif [ "$KEEP_DATA" = true ]; then
    info "Dados da aplicação mantidos em: $APP_DIR"
elif [ ! -d "$APP_DIR" ]; then
    warning "Diretório da aplicação não encontrado: $APP_DIR"
fi

# 4. Remover host do /etc/hosts (apenas desenvolvimento)
if [ "$ENV_TYPE" = "desenvolvimento" ]; then
    DOMAIN=$(grep -l "server_name.*$APP_NAME.docker.local" $NGINX_BASE/*.conf 2>/dev/null | head -1 | xargs grep "server_name" | awk '{print $2}' | sed 's/;//' || echo "")
    if [ -n "$DOMAIN" ]; then
        info "Removendo host do /etc/hosts: $DOMAIN"
        sudo sed -i "/127.0.0.1.*$DOMAIN/d" /etc/hosts
        success "Host removido do /etc/hosts"
    fi
fi

echo ""
echo "🎉 Aplicação '$APP_NAME' removida com sucesso!"
echo ""

if [ "$KEEP_DATA" = false ]; then
    success "✅ Remoção completa realizada!"
    echo "   ⚠️  Todos os dados foram removidos permanentemente"
else
    success "✅ Remoção segura realizada!"
    info "📁 Dados mantidos em: $APP_DIR"
    echo "   Para remover completamente os dados:"
    echo "   ./scripts/app-remove.sh $PHP_VERSION $APP_NAME --delete-data"
fi

echo ""
info "📋 Resumo da remoção:"
echo "   - Configuração Nginx: $([ -f "$NGINX_CONF" ] && echo "❌ Removida" || echo "✅ Removida")"
echo "   - Diretório da app: $([ "$KEEP_DATA" = true ] && echo "📁 Mantido" || echo "❌ Removido")"
echo "   - Nginx: ✅ Recarregado"
if [ "$ENV_TYPE" = "desenvolvimento" ]; then
    echo "   - Host local: ✅ Removido do /etc/hosts"
fi
