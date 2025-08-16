#!/bin/bash

# Script para configurar Laravel Scheduler
# Uso: ./scripts/laravel-cron.sh <php-version> <app-name> [enable|disable|status]

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
    echo "🕒 Configurador de Laravel Scheduler"
    echo "===================================="
    echo ""
    echo "Uso: $0 <php-version> <app-name> [action]"
    echo ""
    echo "Parâmetros:"
    echo "  php-version  Versão do PHP (php84, php74, php56)"
    echo "  app-name     Nome da aplicação"
    echo "  action       enable, disable, status (padrão: enable)"
    echo ""
    echo "Exemplos:"
    echo "  $0 php56 sim10 enable     # Habilitar scheduler"
    echo "  $0 php56 sim10 disable    # Desabilitar scheduler"
    echo "  $0 php56 sim10 status     # Ver status"
    echo ""
}

# Validar argumentos
if [ $# -lt 2 ]; then
    error "Argumentos insuficientes"
    show_help
    exit 1
fi

PHP_VERSION="$1"
APP_NAME="$2"
ACTION="${3:-enable}"

# Validar versão PHP
if [[ ! "$PHP_VERSION" =~ ^(php84|php74|php56)$ ]]; then
    error "Versão PHP inválida: $PHP_VERSION"
    exit 1
fi

CONTAINER_NAME="app-$PHP_VERSION"

# Detectar ambiente
if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
    APP_PATH="/var/www/html/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="desenvolvimento"
else
    APP_PATH="/var/www/html/$PHP_VERSION/$APP_NAME"
    ENV_TYPE="produção"
fi

echo "🕒 Configuração do Laravel Scheduler"
echo "===================================="
info "PHP Version: $PHP_VERSION"
info "App Name: $APP_NAME"
info "Container: $CONTAINER_NAME"
info "App Path: $APP_PATH"
info "Environment: $ENV_TYPE"
info "Action: $ACTION"
echo ""

# Verificar se container está rodando
if ! docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    error "Container $CONTAINER_NAME não está rodando"
    exit 1
fi

# Verificar se aplicação existe
if ! docker exec "$CONTAINER_NAME" [ -d "$APP_PATH" ]; then
    error "Aplicação não encontrada: $APP_PATH"
    exit 1
fi

# Verificar se é Laravel
if ! docker exec "$CONTAINER_NAME" [ -f "$APP_PATH/artisan" ]; then
    error "Arquivo artisan não encontrado. Certifique-se de que é uma aplicação Laravel"
    exit 1
fi

# Função para habilitar scheduler
enable_scheduler() {
    info "Habilitando Laravel Scheduler..."
    
    # Entrada do crontab - roda como root, mas executa artisan como www-data
    CRON_ENTRY="* * * * * docker exec --user www-data $CONTAINER_NAME php $APP_PATH/artisan schedule:run >> /dev/null 2>&1"
    
    # Verificar se já existe no crontab do ROOT
    if sudo crontab -l 2>/dev/null | grep -q "$APP_PATH/artisan schedule:run"; then
        warning "Scheduler já está habilitado para esta aplicação"
        return 0
    fi
    
    # Adicionar ao crontab do ROOT (que tem acesso ao docker)
    (sudo crontab -l 2>/dev/null; echo "$CRON_ENTRY") | sudo crontab -
    
    success "Scheduler habilitado!"
    echo "   Comando: $CRON_ENTRY"
    echo "   📋 Cron executado por: ROOT (sistema)"
    echo "   👤 Artisan executado como: www-data (dentro do container)"
}

# Função para desabilitar scheduler
disable_scheduler() {
    info "Desabilitando Laravel Scheduler..."
    
    # Remover entrada do crontab
    sudo crontab -l 2>/dev/null | grep -v "$APP_PATH/artisan schedule:run" | sudo crontab -
    
    success "Scheduler desabilitado!"
}

# Função para mostrar status
show_status() {
    info "Status do Laravel Scheduler:"
    echo ""
    
    # Debug: mostrar todo o crontab do ROOT
    info "🔍 Crontab atual do ROOT (quem executa o docker):"
    if sudo crontab -l 2>/dev/null; then
        echo ""
    else
        warning "Crontab do root vazio ou erro ao ler"
        echo ""
    fi
    
    # Verificar se existe no crontab do ROOT
    if sudo crontab -l 2>/dev/null | grep -q "$APP_PATH/artisan schedule:run"; then
        success "✅ Scheduler HABILITADO"
        echo ""
        echo "📋 Entrada encontrada no crontab do ROOT:"
        sudo crontab -l 2>/dev/null | grep "$APP_PATH/artisan schedule:run"
        echo ""
        echo "🔄 Fluxo: ROOT executa docker → www-data executa artisan"
    else
        warning "❌ Scheduler DESABILITADO"
        echo ""
        info "🔍 Buscando entradas relacionadas no crontab do ROOT:"
        if sudo crontab -l 2>/dev/null | grep -i "schedule\|artisan"; then
            echo "   (outras entradas encontradas acima)"
        else
            echo "   Nenhuma entrada relacionada encontrada"
        fi
    fi
    
    echo ""
    info "🔍 Testando comando do scheduler:"
    if docker exec --user www-data "$CONTAINER_NAME" php "$APP_PATH/artisan" schedule:run --verbose; then
        success "Comando do scheduler executado com sucesso"
    else
        error "Falha ao executar comando do scheduler"
    fi
}

# Executar ação
case "$ACTION" in
    enable)
        enable_scheduler
        ;;
    disable)
        disable_scheduler
        ;;
    status)
        show_status
        ;;
    *)
        error "Ação inválida: $ACTION"
        show_help
        exit 1
        ;;
esac

echo ""
info "💡 Dicas:"
echo "   • Verifique o arquivo app/Console/Kernel.php para ver tarefas agendadas"
echo "   • Use 'php artisan schedule:list' para listar comandos agendados"
echo "   • Logs do scheduler aparecem nos logs do Laravel"
echo ""
