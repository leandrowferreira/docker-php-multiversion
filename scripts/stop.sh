#!/bin/bash

# Script para parar o sistema Docker multi-PHP
# Este script para todos os containers do sistema de forma ordenada

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

# Função para detectar ambiente
detect_environment() {
    if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
        echo "desenvolvimento"
    elif [ -d "/sistemas" ]; then
        echo "produção"
    else
        echo "desconhecido"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "🛑 Script para parar o sistema Docker multi-PHP"
    echo "=============================================="
    echo ""
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --remove-volumes   Remove também os volumes (dados serão perdidos!)"
    echo "  --force           Para containers mesmo se houver erros"
    echo "  --backup          Faz backup antes de parar (apenas produção)"
    echo "  -h, --help        Mostrar esta ajuda"
    echo ""
    echo "⚠️  ATENÇÃO: --remove-volumes apagará todos os dados!"
    echo ""
    echo "Exemplos:"
    echo "  $0                      # Para todos os containers"
    echo "  $0 --backup            # Backup + para containers"
    echo "  $0 --remove-volumes     # Para e remove volumes (CUIDADO!)"
    echo ""
}

# Variáveis padrão
REMOVE_VOLUMES=false
FORCE_STOP=false
BACKUP_BEFORE_STOP=false

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --force)
            FORCE_STOP=true
            shift
            ;;
        --backup)
            BACKUP_BEFORE_STOP=true
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

echo "🛑 Parando sistema Docker multi-PHP"
echo "==================================="

# Detectar ambiente
ENV_TYPE=$(detect_environment)
info "Ambiente detectado: $(echo $ENV_TYPE | tr '[:lower:]' '[:upper:]')"

# Verificar se estamos no diretório correto
if [ "$ENV_TYPE" = "desenvolvimento" ]; then
    if [ ! -f "docker-compose.yml" ] || [ ! -f "docker-compose.dev.yml" ]; then
        error "Arquivos docker-compose não encontrados no diretório atual"
        exit 1
    fi
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
elif [ "$ENV_TYPE" = "produção" ]; then
    if [ ! -f "docker-compose.yml" ]; then
        error "Arquivo docker-compose.yml não encontrado"
        exit 1
    fi
    COMPOSE_FILES="-f docker-compose.yml"
else
    error "Ambiente não reconhecido. Execute no diretório correto do projeto"
    exit 1
fi

# Fazer backup se solicitado (apenas produção)
if [ "$BACKUP_BEFORE_STOP" = true ]; then
    if [ "$ENV_TYPE" = "produção" ] && [ -f "scripts/backup-db.sh" ]; then
        info "Executando backup antes de parar..."
        if ./scripts/backup-db.sh; then
            success "Backup realizado com sucesso"
        else
            warning "Falha no backup, continuando mesmo assim..."
        fi
    else
        warning "Backup não disponível neste ambiente"
    fi
fi

# Verificar se há containers rodando
if ! docker compose $COMPOSE_FILES ps --services --filter "status=running" | grep -q .; then
    warning "Nenhum container está rodando"
    exit 0
fi

# Mostrar containers que serão parados
info "Containers que serão parados:"
docker compose $COMPOSE_FILES ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

# Parar containers de aplicação primeiro (ordem inversa do start)
info "Parando containers de aplicação..."

# Para containers PHP
for php_version in php84 php74 php56; do
    if docker compose $COMPOSE_FILES ps | grep -q "app-$php_version"; then
        info "Parando $php_version..."
        if [ "$FORCE_STOP" = true ]; then
            docker compose $COMPOSE_FILES kill app-$php_version 2>/dev/null || true
        else
            docker compose $COMPOSE_FILES stop app-$php_version
        fi
    fi
done

# Para Nginx
if docker compose $COMPOSE_FILES ps | grep -q nginx; then
    info "Parando Nginx..."
    if [ "$FORCE_STOP" = true ]; then
        docker compose $COMPOSE_FILES kill nginx 2>/dev/null || true
    else
        docker compose $COMPOSE_FILES stop nginx
    fi
fi

# Para PHPMyAdmin
if docker compose $COMPOSE_FILES ps | grep -q phpmyadmin; then
    info "Parando PHPMyAdmin..."
    if [ "$FORCE_STOP" = true ]; then
        docker compose $COMPOSE_FILES kill phpmyadmin 2>/dev/null || true
    else
        docker compose $COMPOSE_FILES stop phpmyadmin
    fi
fi

# Para bancos de dados (mais cuidadoso)
info "Parando bancos de dados..."
for db in mysql8 mysql57; do
    if docker compose $COMPOSE_FILES ps | grep -q $db; then
        info "Parando $db..."
        if [ "$FORCE_STOP" = true ]; then
            docker compose $COMPOSE_FILES kill $db 2>/dev/null || true
        else
            # Dar mais tempo para bancos de dados
            docker compose $COMPOSE_FILES stop -t 30 $db
        fi
    fi
done

# Para Redis
if docker compose $COMPOSE_FILES ps | grep -q redis; then
    info "Parando Redis..."
    if [ "$FORCE_STOP" = true ]; then
        docker compose $COMPOSE_FILES kill redis 2>/dev/null || true
    else
        docker compose $COMPOSE_FILES stop redis
    fi
fi

# Para todos os containers restantes
info "Parando containers restantes..."
if [ "$FORCE_STOP" = true ]; then
    docker compose $COMPOSE_FILES kill
else
    docker compose $COMPOSE_FILES stop
fi

success "Todos os containers foram parados"

# Remover volumes se solicitado
if [ "$REMOVE_VOLUMES" = true ]; then
    warning "ATENÇÃO: Removendo volumes - todos os dados serão perdidos!"
    read -p "Tem certeza? Digite 'CONFIRMO' para continuar: " confirm
    
    if [ "$confirm" = "CONFIRMO" ]; then
        info "Removendo containers e volumes..."
        docker compose $COMPOSE_FILES down -v --remove-orphans
        success "Containers e volumes removidos"
        
        # Remover volumes órfãos
        if docker volume ls -q -f dangling=true | grep -q .; then
            info "Removendo volumes órfãos..."
            docker volume prune -f
        fi
    else
        info "Remoção de volumes cancelada"
    fi
else
    # Apenas remover containers (manter volumes)
    info "Removendo containers (mantendo volumes)..."
    docker compose $COMPOSE_FILES down --remove-orphans
fi

# Mostrar resumo final
echo ""
info "📊 Status final:"
if docker compose $COMPOSE_FILES ps --services 2>/dev/null | grep -q .; then
    warning "Alguns serviços ainda podem estar listados:"
    docker compose $COMPOSE_FILES ps
else
    success "Todos os serviços foram parados e removidos"
fi

# Verificar uso de espaço
echo ""
info "💾 Uso de espaço Docker:"
docker system df

# Sugestões de limpeza
echo ""
info "🧹 Para limpeza adicional:"
echo "  docker system prune       # Remove containers/redes/imagens não utilizadas"
echo "  docker system prune -a    # Remove TODAS as imagens não utilizadas"
echo "  docker volume prune       # Remove volumes não utilizados"

echo ""
success "✅ Sistema parado com sucesso!"

if [ "$REMOVE_VOLUMES" = false ]; then
    info "💡 Para reiniciar: ./scripts/start.sh"
    info "🗑️  Para remover dados: ./scripts/stop.sh --remove-volumes"
fi
