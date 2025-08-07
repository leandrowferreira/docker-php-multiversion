#!/bin/bash

# Script para listar aplicações e seus status
# Mostra informações detalhadas sobre cada aplicação rodando
# Uso: ./app-list.sh [--json] [--verbose]

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
detail() { echo -e "${CYAN}   $1${NC}"; }
header() { echo -e "${PURPLE}$1${NC}"; }

# Função para mostrar ajuda
show_help() {
    echo "📋 Script para listar aplicações"
    echo "================================"
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --json         Saída em formato JSON"
    echo "  --verbose      Mostrar informações detalhadas"
    echo "  --status-only  Mostrar apenas status dos containers"
    echo "  -h, --help     Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Listagem padrão"
    echo "  $0 --verbose          # Com informações detalhadas"
    echo "  $0 --json             # Saída em JSON"
    echo ""
}

# Variáveis padrão
JSON_OUTPUT=false
VERBOSE=false
STATUS_ONLY=false

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --status-only)
            STATUS_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Detectar ambiente
detect_environment() {
    if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
        echo "desenvolvimento"
    else
        echo "producao"
    fi
}

# Verificar se é Laravel
is_laravel_app() {
    local app_dir="$1"
    
    if [ -f "$app_dir/artisan" ] || \
       [ -f "$app_dir/composer.json" ] || \
       [ -d "$app_dir/app" ] || \
       [ -d "$app_dir/config" ] || \
       [ -d "$app_dir/routes" ]; then
        return 0  # É Laravel
    else
        return 1  # Não é Laravel
    fi
}

# Obter versão do Laravel
get_laravel_version() {
    local app_dir="$1"
    
    if [ -f "$app_dir/composer.json" ]; then
        # Tentar extrair versão do composer.json
        version=$(grep -o '"laravel/framework": "[^"]*"' "$app_dir/composer.json" 2>/dev/null | cut -d'"' -f4 | head -1)
        if [ -n "$version" ]; then
            echo "$version"
            return
        fi
    fi
    
    if [ -f "$app_dir/artisan" ]; then
        echo "Detectado (artisan presente)"
    else
        echo "Estrutura básica"
    fi
}

# Obter informações do PHP
get_php_info() {
    local php_version="$1"
    local container_name="app-$php_version"
    
    if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        # Container está rodando
        php_ver=$(docker exec "$container_name" php -v 2>/dev/null | head -1 | grep -o 'PHP [0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "$php_ver"
    else
        case $php_version in
            php84) echo "PHP 8.4.x (container parado)" ;;
            php74) echo "PHP 7.4.x (container parado)" ;;
            php56) echo "PHP 5.6.x (container parado)" ;;
            *) echo "PHP $php_version (container parado)" ;;
        esac
    fi
}

# Verificar status do container
get_container_status() {
    local php_version="$1"
    local container_name="app-$php_version"
    
    if docker ps --format "{{.Names}}\t{{.Status}}" | grep -q "^$container_name"; then
        status=$(docker ps --format "{{.Names}}\t{{.Status}}" | grep "^$container_name" | cut -f2)
        echo "🟢 Rodando ($status)"
    elif docker ps -a --format "{{.Names}}\t{{.Status}}" | grep -q "^$container_name"; then
        status=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep "^$container_name" | cut -f2)
        echo "🔴 Parado ($status)"
    else
        echo "⚪ Container não encontrado"
    fi
}

# Verificar configuração do Nginx
get_nginx_status() {
    local app_name="$1"
    local nginx_conf="nginx/conf.d/app-$app_name.conf"
    
    if [ -f "$nginx_conf" ]; then
        # Verificar se o nginx está rodando e se a configuração está carregada
        if docker ps --format "{{.Names}}" | grep -q "nginx-proxy"; then
            # Tentar testar a configuração
            if docker exec nginx-proxy nginx -t &>/dev/null; then
                echo "🟢 Configurado"
            else
                echo "🟡 Config com erro"
            fi
        else
            echo "🔴 Nginx parado"
        fi
    else
        echo "⚪ Sem configuração"
    fi
}

# Obter domínios configurados
get_domains() {
    local app_name="$1"
    local nginx_conf="nginx/conf.d/app-$app_name.conf"
    
    if [ -f "$nginx_conf" ]; then
        domains=$(grep -o 'server_name [^;]*' "$nginx_conf" | sed 's/server_name //' | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')
        echo "$domains" | xargs
    else
        echo "N/A"
    fi
}

# Verificar tamanho da aplicação
get_app_size() {
    local app_dir="$1"
    
    if [ -d "$app_dir" ]; then
        size=$(du -sh "$app_dir" 2>/dev/null | cut -f1)
        echo "$size"
    else
        echo "N/A"
    fi
}

# Verificar última modificação
get_last_modified() {
    local app_dir="$1"
    
    if [ -d "$app_dir" ]; then
        # Encontrar arquivo mais recentemente modificado
        last_file=$(find "$app_dir" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [ -n "$last_file" ]; then
            last_date=$(stat -c %y "$last_file" 2>/dev/null | cut -d' ' -f1)
            echo "$last_date"
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

# Listar aplicações
list_applications() {
    local env_type=$(detect_environment)
    local apps_found=()
    
    # Determinar diretório base
    if [ "$env_type" = "desenvolvimento" ]; then
        base_dir="./apps"
    else
        base_dir="/sistemas/apps"
    fi
    
    if [ ! -d "$base_dir" ]; then
        error "Diretório de aplicações não encontrado: $base_dir"
        return 1
    fi
    
    # Buscar aplicações em todas as versões PHP
    for php_version in php84 php74 php56; do
        php_dir="$base_dir/$php_version"
        if [ -d "$php_dir" ]; then
            for app_dir in "$php_dir"/*; do
                if [ -d "$app_dir" ]; then
                    app_name=$(basename "$app_dir")
                    apps_found+=("$app_name:$php_version:$app_dir")
                fi
            done
        fi
    done
    
    # Se não encontrou nenhuma app
    if [ ${#apps_found[@]} -eq 0 ]; then
        warning "Nenhuma aplicação encontrada"
        return 0
    fi
    
    # Saída em JSON
    if [ "$JSON_OUTPUT" = true ]; then
        echo "{"
        echo "  \"environment\": \"$env_type\","
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"applications\": ["
        
        local first=true
        for app_data in "${apps_found[@]}"; do
            IFS=':' read -r app_name php_version app_dir <<< "$app_data"
            
            [ "$first" = false ] && echo ","
            first=false
            
            is_laravel=$(is_laravel_app "$app_dir" && echo "true" || echo "false")
            laravel_version=$(get_laravel_version "$app_dir")
            php_info=$(get_php_info "$php_version")
            container_status=$(get_container_status "$php_version")
            nginx_status=$(get_nginx_status "$app_name")
            domains=$(get_domains "$app_name")
            app_size=$(get_app_size "$app_dir")
            last_modified=$(get_last_modified "$app_dir")
            
            echo "    {"
            echo "      \"name\": \"$app_name\","
            echo "      \"php_version\": \"$php_version\","
            echo "      \"path\": \"$app_dir\","
            echo "      \"is_laravel\": $is_laravel,"
            echo "      \"laravel_version\": \"$laravel_version\","
            echo "      \"php_info\": \"$php_info\","
            echo "      \"container_status\": \"$container_status\","
            echo "      \"nginx_status\": \"$nginx_status\","
            echo "      \"domains\": \"$domains\","
            echo "      \"size\": \"$app_size\","
            echo "      \"last_modified\": \"$last_modified\""
            echo -n "    }"
        done
        
        echo ""
        echo "  ]"
        echo "}"
        return 0
    fi
    
    # Status apenas dos containers
    if [ "$STATUS_ONLY" = true ]; then
        header "📊 Status dos Containers PHP"
        echo "=============================="
        
        for php_version in php84 php74 php56; do
            status=$(get_container_status "$php_version")
            php_info=$(get_php_info "$php_version")
            echo "$php_version: $status - $php_info"
        done
        
        echo ""
        nginx_status="⚪ Não verificado"
        if docker ps --format "{{.Names}}" | grep -q "nginx-proxy"; then
            nginx_status="🟢 Rodando"
        elif docker ps -a --format "{{.Names}}" | grep -q "nginx-proxy"; then
            nginx_status="🔴 Parado"
        fi
        echo "nginx: $nginx_status"
        
        return 0
    fi
    
    # Saída padrão formatada
    header "📋 Aplicações Encontradas ($env_type)"
    echo "================================================="
    echo ""
    
    # Cabeçalho da tabela
    printf "%-15s %-8s %-12s %-20s %-15s %s\n" "APLICAÇÃO" "PHP" "TIPO" "CONTAINER" "NGINX" "DOMÍNIOS"
    echo "$(printf '%.80s' "$(yes '-' | head -80 | tr -d '\n')")"
    
    for app_data in "${apps_found[@]}"; do
        IFS=':' read -r app_name php_version app_dir <<< "$app_data"
        
        # Informações básicas
        if is_laravel_app "$app_dir"; then
            app_type="Laravel"
        else
            app_type="PHP App"
        fi
        
        container_status=$(get_container_status "$php_version" | sed 's/[🟢🔴⚪] //')
        nginx_status=$(get_nginx_status "$app_name" | sed 's/[🟢🔴🟡⚪] //')
        domains=$(get_domains "$app_name")
        
        # Truncar domínios se muito longo
        if [ ${#domains} -gt 25 ]; then
            domains="${domains:0:22}..."
        fi
        
        printf "%-15s %-8s %-12s %-20s %-15s %s\n" \
            "$app_name" \
            "$php_version" \
            "$app_type" \
            "${container_status:0:18}" \
            "${nginx_status:0:13}" \
            "$domains"
    done
    
    # Informações detalhadas se solicitado
    if [ "$VERBOSE" = true ]; then
        echo ""
        header "📋 Informações Detalhadas"
        echo "=========================="
        echo ""
        
        for app_data in "${apps_found[@]}"; do
            IFS=':' read -r app_name php_version app_dir <<< "$app_data"
            
            echo "🔹 $app_name ($php_version)"
            detail "Caminho: $app_dir"
            detail "Tamanho: $(get_app_size "$app_dir")"
            detail "Última modificação: $(get_last_modified "$app_dir")"
            detail "Container: $(get_container_status "$php_version")"
            detail "Nginx: $(get_nginx_status "$app_name")"
            detail "PHP: $(get_php_info "$php_version")"
            
            if is_laravel_app "$app_dir"; then
                laravel_version=$(get_laravel_version "$app_dir")
                detail "Laravel: $laravel_version"
                
                # Verificar arquivo .env
                if [ -f "$app_dir/.env" ]; then
                    detail "Configuração: .env presente"
                elif [ -f "$app_dir/.env.example" ]; then
                    detail "Configuração: apenas .env.example"
                else
                    detail "Configuração: nenhum arquivo .env"
                fi
            fi
            
            domains=$(get_domains "$app_name")
            if [ "$domains" != "N/A" ]; then
                detail "Domínios: $domains"
            fi
            
            echo ""
        done
    fi
    
    # Resumo final
    echo ""
    header "📊 Resumo do Sistema"
    echo "===================="
    
    total_apps=${#apps_found[@]}
    laravel_count=0
    php84_count=0
    php74_count=0
    php56_count=0
    
    for app_data in "${apps_found[@]}"; do
        IFS=':' read -r app_name php_version app_dir <<< "$app_data"
        
        if is_laravel_app "$app_dir"; then
            laravel_count=$((laravel_count + 1))
        fi
        
        case $php_version in
            php84) php84_count=$((php84_count + 1)) ;;
            php74) php74_count=$((php74_count + 1)) ;;
            php56) php56_count=$((php56_count + 1)) ;;
        esac
    done
    
    info "Total de aplicações: $total_apps"
    info "Aplicações Laravel: $laravel_count"
    info "PHP 8.4: $php84_count apps"
    info "PHP 7.4: $php74_count apps"
    info "PHP 5.6: $php56_count apps"
    
    # Status dos serviços principais
    echo ""
    info "Status dos serviços:"
    for service in nginx-proxy mysql8 mysql57 redis-cache; do
        if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
            success "$service: Rodando"
        elif docker ps -a --format "{{.Names}}" | grep -q "^$service$"; then
            warning "$service: Parado"
        else
            info "$service: Não encontrado"
        fi
    done
}

# Executar função principal
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    list_applications
fi
