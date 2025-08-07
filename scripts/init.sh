#!/bin/bash

# Script de inicialização do sistema de containers
# Detecta automaticamente o ambiente e configura a estrutura necessária
# 
# Uso:
#   ./init.sh           # Configurar estrutura E iniciar containers
#   ./init.sh --setup   # Apenas configurar estrutura (não iniciar containers)

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

# Verificar argumentos
SETUP_ONLY=false
if [ "$1" = "--setup" ]; then
    SETUP_ONLY=true
fi

echo "🚀 Inicializando Sistema de Containers"
echo "======================================"

# Detectar ambiente
detect_environment() {
    if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
        echo "desenvolvimento"
    else
        echo "producao"
    fi
}

# Definir variável global
export ENV_TYPE=$(detect_environment)
info "Ambiente detectado: $([ "$ENV_TYPE" = "desenvolvimento" ] && echo "DESENVOLVIMENTO" || echo "PRODUÇÃO")"

# Configurar diretórios baseado no ambiente
setup_directories() {
    if [ "$ENV_TYPE" = "producao" ]; then
        info "Configurando estrutura de produção em /sistemas..."
        
        # Verificar se /sistemas já existe
        if [ -d "/sistemas" ]; then
            warning "Diretório /sistemas já existe"
            info "Verificando estrutura existente..."
        else
            info "Criando estrutura /sistemas..."
            
            # Criar diretórios base
            sudo mkdir -p /sistemas/{apps,mysql8,mysql57,redis,backups,logs}
            
            # Criar subdiretórios para aplicações
            sudo mkdir -p /sistemas/apps/{php84,php74,php56}
            
            # Criar diretórios para bancos de dados
            sudo mkdir -p /sistemas/mysql8/{data,conf,logs}
            sudo mkdir -p /sistemas/mysql57/{data,conf,logs}
            
            # Criar diretório para Redis
            sudo mkdir -p /sistemas/redis/data
            
            # Ajustar permissões
            sudo chown -R $USER:$USER /sistemas
            sudo chmod -R 755 /sistemas
            
            success "Estrutura /sistemas criada"
        fi
        
        # Verificar estrutura completa
        missing_dirs=()
        for dir in "/sistemas/apps/php84" "/sistemas/apps/php74" "/sistemas/apps/php56" \
                   "/sistemas/mysql8/data" "/sistemas/mysql57/data" "/sistemas/redis/data"; do
            if [ ! -d "$dir" ]; then
                missing_dirs+=("$dir")
            fi
        done
        
        if [ ${#missing_dirs[@]} -gt 0 ]; then
            warning "Diretórios ausentes detectados, criando..."
            for dir in "${missing_dirs[@]}"; do
                sudo mkdir -p "$dir"
                info "Criado: $dir"
            done
            sudo chown -R $USER:$USER /sistemas
        fi
        
    else
        info "Configurando estrutura de desenvolvimento..."
        
        # Verificar se ./apps existe
        if [ ! -d "apps" ]; then
            info "Criando estrutura local de desenvolvimento..."
            mkdir -p apps/{php84,php74,php56}
            success "Estrutura ./apps criada"
        else
            info "Estrutura ./apps já existe"
        fi
        
        # Criar diretórios para dados em desenvolvimento
        info "Criando diretórios de dados para desenvolvimento..."
        mkdir -p mysql/data/{mysql8,mysql57}
        mkdir -p redis/data
        success "Estrutura de dados criada"
    fi
}

# Configurar logs locais
setup_local_logs() {
    info "Configurando diretórios de logs locais..."
    mkdir -p logs/{nginx,php84,php74,php56,mysql}
    success "Logs locais configurados"
}

# Configurar Docker
setup_docker() {
    info "Configurando Docker..."
    
    # Verificar se Docker está instalado
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado"
        return 1
    fi
    
    # Habilitar auto-start (apenas em produção)
    if [ "$ENV_TYPE" = "producao" ]; then
        sudo systemctl enable docker
        success "Auto-start do Docker habilitado"
    fi
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        warning "Docker não está rodando"
        if [ "$ENV_TYPE" = "producao" ]; then
            info "Iniciando Docker..."
            sudo systemctl start docker
        else
            warning "Inicie o Docker manualmente: sudo systemctl start docker"
        fi
    else
        success "Docker está rodando"
    fi
}

# Iniciar containers
start_containers() {
    info "Iniciando containers..."
    
    # Verificar se docker compose está disponível (v2 ou v1)
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        error "Docker Compose não está disponível"
        return 1
    fi
    
    # Determinar arquivos de configuração baseado no ambiente
    if [ "$ENV_TYPE" = "desenvolvimento" ] && [ -f "docker-compose.dev.yml" ]; then
        COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
        info "Usando configuração de desenvolvimento"
    else
        COMPOSE_FILES=""
        info "Usando configuração de produção"
    fi
    
    info "Usando comando: $COMPOSE_CMD $COMPOSE_FILES"
    
    # Limpar containers conflitantes
    info "Limpando containers existentes..."
    $COMPOSE_CMD $COMPOSE_FILES down --remove-orphans 2>/dev/null || true
    
    # Remover containers com nomes conflitantes (se existirem)
    conflicting_containers=("nginx-proxy" "mysql8" "mysql57" "redis-cache" "laravel-php84" "laravel-php74" "laravel-php56")
    for container in "${conflicting_containers[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^$container$"; then
            warning "Removendo container conflitante: $container"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    # Iniciar containers
    info "Executando: $COMPOSE_CMD $COMPOSE_FILES up -d"
    if $COMPOSE_CMD $COMPOSE_FILES up -d; then
        success "Containers iniciados com sucesso!"
        
        # Aguardar containers ficarem prontos
        info "Aguardando containers ficarem prontos..."
        sleep 8
        
        # Verificar status
        info "Status dos containers:"
        $COMPOSE_CMD $COMPOSE_FILES ps
        
        # Verificar se todos estão rodando
        failed_containers=$($COMPOSE_CMD $COMPOSE_FILES ps --filter "status=exited" -q 2>/dev/null || true)
        if [ -n "$failed_containers" ]; then
            warning "Alguns containers falharam ao iniciar"
            info "Execute '$COMPOSE_CMD $COMPOSE_FILES logs' para ver os erros"
            return 1
        fi
        
        success "Todos os containers estão rodando!"
        return 0
    else
        error "Falha ao iniciar containers"
        return 1
    fi
}
check_essential_files() {
    info "Verificando arquivos essenciais..."
    
    essential_files=(
        "docker-compose.yml"
        "nginx/nginx.conf"
        "nginx/templates/php84-http-template.conf"
        "scripts/add-app.sh"
    )
    
    missing_files=()
    for file in "${essential_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        error "Arquivos essenciais ausentes:"
        for file in "${missing_files[@]}"; do
            echo "   - $file"
        done
        return 1
    fi
    
    success "Todos os arquivos essenciais presentes"
}

# Executar configuração
main() {
    check_essential_files
    setup_directories
    setup_local_logs
    setup_docker
    
    # Iniciar containers (a menos que seja só setup)
    if [ "$SETUP_ONLY" = false ]; then
        echo ""
        info "🐳 Iniciando sistema de containers..."
        if start_containers; then
            echo ""
            success "🎉 Sistema inicializado e containers rodando!"
            
            # Mostrar informações úteis
            echo ""
            info "📊 Containers ativos:"
            $COMPOSE_CMD $COMPOSE_FILES ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}" 2>/dev/null || $COMPOSE_CMD $COMPOSE_FILES ps
            
        else
            echo ""
            error "❌ Falha ao iniciar containers"
            warning "Verifique os logs com: $COMPOSE_CMD $COMPOSE_FILES logs"
            return 1
        fi
    else
        echo ""
        success "🎉 Estrutura configurada com sucesso!"
        info "Para iniciar os containers execute: docker compose up -d"
    fi
    
    echo ""
    success "🎉 Sistema inicializado com sucesso!"
    echo ""
    
    if [ "$ENV_TYPE" = "producao" ]; then
        echo "📁 Estrutura de produção:"
        echo "   /sistemas/apps/php84     - Aplicações PHP 8.4"
        echo "   /sistemas/apps/php74     - Aplicações PHP 7.4"
        echo "   /sistemas/apps/php56     - Aplicações PHP 5.6"
        echo "   /sistemas/mysql8/data    - Dados MySQL 8.0"
        echo "   /sistemas/mysql57/data   - Dados MySQL 5.7"
        echo "   /sistemas/redis/data     - Dados Redis"
    else
        echo "📁 Estrutura de desenvolvimento:"
        echo "   ./apps/php84             - Aplicações PHP 8.4"
        echo "   ./apps/php74             - Aplicações PHP 7.4"
        echo "   ./apps/php56             - Aplicações PHP 5.6"
        echo "   ./mysql/data/mysql8      - Dados MySQL 8.0"
        echo "   ./mysql/data/mysql57     - Dados MySQL 5.7"
        echo "   ./redis/data             - Dados Redis"
    fi
    
    echo ""
    echo "🔧 Próximos passos:"
    echo "   1. ./scripts/add-app.sh <nome> <php> <dom> # Adicionar aplicação"
    echo "   2. ./scripts/monitor.sh                    # Monitorar sistema"
    echo "   3. docker compose logs                     # Ver logs dos containers"
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi