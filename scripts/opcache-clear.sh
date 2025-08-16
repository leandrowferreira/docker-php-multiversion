#!/bin/bash

# Script para limpar OPcache de todas as versões PHP
# Uso: ./scripts/opcache-clear.sh

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

echo "🗑️  Limpando OPcache de Todas as Versões PHP"
echo "============================================="
echo ""

# Lista de containers PHP
PHP_CONTAINERS=(
    "app-php84:8.4"
    "app-php74:7.4"
    "app-php56:5.6"
)

# Função para limpar OPcache de um container
clear_opcache() {
    local container_name="$1"
    local php_version="$2"
    
    info "Verificando container $container_name (PHP $php_version)..."
    
    # Verificar se o container está rodando
    if ! docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        warning "Container $container_name não está rodando"
        return 1
    fi
    
    # Limpar OPcache
    if docker exec "$container_name" php -r "
        if (function_exists('opcache_reset')) {
            if (opcache_reset()) {
                echo 'OPcache cleared successfully';
            } else {
                echo 'Failed to clear OPcache';
                exit(1);
            }
        } else {
            echo 'OPcache not available';
            exit(1);
        }
    " 2>/dev/null; then
        success "OPcache limpo: PHP $php_version"
        return 0
    else
        error "Falha ao limpar OPcache: PHP $php_version"
        return 1
    fi
}

# Função para mostrar status do OPcache
show_opcache_status() {
    local container_name="$1"
    local php_version="$2"
    
    if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        local status=$(docker exec "$container_name" php -r "
            if (function_exists('opcache_get_status')) {
                \$status = opcache_get_status();
                if (\$status) {
                    echo 'Enabled: ' . (\$status['opcache_enabled'] ? 'Yes' : 'No') . ' | ';
                    echo 'Files: ' . \$status['opcache_statistics']['num_cached_scripts'] . ' | ';
                    echo 'Memory: ' . round(\$status['memory_usage']['used_memory']/1024/1024, 1) . 'MB';
                } else {
                    echo 'Not running';
                }
            } else {
                echo 'Not available';
            }
        " 2>/dev/null || echo "Error")
        
        echo "   📊 PHP $php_version: $status"
    fi
}

# Processar cada container
cleared_count=0
total_count=${#PHP_CONTAINERS[@]}

for container_info in "${PHP_CONTAINERS[@]}"; do
    IFS=':' read -r container_name php_version <<< "$container_info"
    
    if clear_opcache "$container_name" "$php_version"; then
        ((cleared_count++))
    fi
done

echo ""
echo "📊 Status Atual do OPcache:"
echo "=========================="
for container_info in "${PHP_CONTAINERS[@]}"; do
    IFS=':' read -r container_name php_version <<< "$container_info"
    show_opcache_status "$container_name" "$php_version"
done

echo ""
if [ $cleared_count -eq $total_count ]; then
    success "🎉 OPcache limpo em todas as $total_count versões PHP!"
elif [ $cleared_count -gt 0 ]; then
    warning "⚠️  OPcache limpo em $cleared_count de $total_count versões PHP"
else
    error "❌ Falha ao limpar OPcache em todas as versões"
    exit 1
fi

echo ""
info "💡 Dicas:"
echo "   • Para desabilitar OPcache em desenvolvimento, edite docker/php*/php.ini"
echo "   • Configure opcache.revalidate_freq=0 para desenvolvimento"
echo "   • Use Ctrl+F5 no browser para forçar refresh completo"
echo "   • Para refresh automático: ./scripts/opcache-clear.sh"
echo ""

# Opcional: Mostrar comando para automatizar
echo "🔄 Para automatizar, você pode criar um alias:"
echo "   alias opclear='./scripts/opcache-clear.sh'"
echo ""
