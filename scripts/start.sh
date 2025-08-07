#!/bin/bash

# Script de inicialização do sistema de containers
# Detecta automaticamente o ambiente e configura a estrutura necessária
# 
# Uso:
#   ./start.sh             # Configurar estrutura E iniciar containers
#   ./start.sh --setup     # Apenas configurar estrutura (não iniciar containers)
#   ./start.sh --autostart # Configurar auto-start do sistema (systemd)

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
AUTOSTART=false
# Verificar argumentos
SETUP_ONLY=false
AUTOSTART=false

show_help() {
    echo "🚀 Script de Inicialização do Sistema de Containers"
    echo "==================================================="
    echo ""
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  (sem opção)     Configurar estrutura E iniciar containers"
    echo "  --setup         Apenas configurar estrutura (não iniciar containers)"
    echo "  --autostart     Configurar auto-start do sistema com systemd"
    echo "  -h, --help      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Configuração completa + iniciar containers"
    echo "  $0 --setup           # Apenas preparar estrutura"
    echo "  $0 --autostart       # Configurar para iniciar automaticamente no boot"
    echo ""
    echo "ℹ️  O script detecta automaticamente se está em desenvolvimento ou produção"
    echo ""
}

case "$1" in
    --setup)
        SETUP_ONLY=true
        ;;
    --autostart)
        AUTOSTART=true
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        # Sem argumentos - comportamento padrão
        ;;
    *)
        echo "❌ Opção desconhecida: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

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

# Verificar e criar arquivo .env se necessário
setup_env_file() {
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            info "Arquivo .env não encontrado, copiando de .env.example..."
            cp ".env.example" ".env"
            success "Arquivo .env criado a partir do .env.example"
            warning "⚠️  Verifique as configurações em .env antes de usar em produção!"
        else
            warning "Nem .env nem .env.example encontrados. Usando valores padrão dos containers."
        fi
    else
        info "Arquivo .env encontrado ✅"
    fi
}

# Executar setup do .env
setup_env_file

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
    conflicting_containers=("nginx-proxy" "mysql8" "mysql57" "redis-cache" "app-php84" "app-php74" "app-php56")
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
        "scripts/app-create.sh"
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

# Configurar auto-start com systemd
setup_autostart() {
    info "Configurando auto-start do sistema..."
    
    # Verificar se é ambiente de produção
    if [ "$ENV_TYPE" != "producao" ]; then
        warning "Auto-start recomendado apenas em produção"
        read -p "Continuar mesmo assim? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Auto-start cancelado"
            return 0
        fi
    fi
    
    # Verificar se systemd está disponível
    if ! command -v systemctl &> /dev/null; then
        error "systemctl não está disponível. Auto-start requer systemd."
        return 1
    fi
    
    # Determinar comando do Docker Compose
    local compose_cmd
    if command -v docker-compose &> /dev/null; then
        compose_cmd="docker-compose"
    elif docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    else
        error "Docker Compose não está disponível"
        return 1
    fi
    
    # Determinar arquivos de configuração
    local compose_files=""
    if [ "$ENV_TYPE" = "desenvolvimento" ] && [ -f "docker-compose.dev.yml" ]; then
        compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    fi
    
    # Configurações do serviço
    local service_name="sistemas-docker"
    local service_file="/etc/systemd/system/$service_name.service"
    local work_dir="$(realpath .)"
    
    info "Criando serviço systemd: $service_name"
    info "Diretório de trabalho: $work_dir"
    info "Comando: $compose_cmd $compose_files"
    
    # Criar arquivo de serviço systemd
    sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=Sistemas Docker Compose Auto-Start
Requires=docker.service
After=docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$work_dir
ExecStart=$compose_cmd $compose_files up -d
ExecStop=$compose_cmd $compose_files down
TimeoutStartSec=300
TimeoutStopSec=120
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Recarregar systemd
    sudo systemctl daemon-reload
    
    # Habilitar o serviço
    sudo systemctl enable "$service_name"
    
    success "Auto-start configurado com sucesso!"
    echo ""
    info "📋 Comandos de gerenciamento:"
    echo "   sudo systemctl start $service_name    - Iniciar manualmente"
    echo "   sudo systemctl stop $service_name     - Parar manualmente"
    echo "   sudo systemctl status $service_name   - Ver status"
    echo "   sudo systemctl disable $service_name  - Desabilitar auto-start"
    echo "   sudo systemctl restart $service_name  - Reiniciar serviço"
    echo ""
    warning "O sistema iniciará automaticamente quando a máquina for reiniciada"
    
    # Testar o serviço
    read -p "Testar o serviço agora? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Testando serviço..."
        if sudo systemctl start "$service_name"; then
            success "Serviço iniciado com sucesso!"
            sudo systemctl status "$service_name" --no-pager -l
        else
            error "Falha ao iniciar serviço"
            warning "Verifique os logs: sudo journalctl -u $service_name -f"
        fi
    fi
}

# Executar configuração
main() {
    # Modo auto-start
    if [ "$AUTOSTART" = true ]; then
        echo "🚀 Configurando Auto-Start do Sistema"
        echo "====================================="
        
        # Detectar ambiente primeiro
        export ENV_TYPE=$(detect_environment)
        info "Ambiente detectado: $([ "$ENV_TYPE" = "desenvolvimento" ] && echo "DESENVOLVIMENTO" || echo "PRODUÇÃO")"
        
        check_essential_files
        setup_autostart
        return $?
    fi
    
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
    echo "   1. ./scripts/app-create.sh <php> <nome> <dom> # Criar aplicação"
    echo "   2. ./scripts/app-list.sh                    # Listar aplicações"
    echo "   3. ./scripts/monitor.sh                     # Monitorar sistema"
    echo "   4. docker compose logs                      # Ver logs dos containers"
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi