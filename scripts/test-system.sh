#!/bin/bash

# Script de teste para verificar se o sistema está funcionando corretamente

set -e

echo "🧪 Testando Sistema de Containers Laravel"
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Teste 1: Verificar se Docker está rodando
echo "🔍 Verificando Docker..."
if docker info >/dev/null 2>&1; then
    success "Docker está rodando"
else
    error "Docker não está rodando"
    exit 1
fi

# Teste 2: Verificar se Docker Compose está disponível
echo "🔍 Verificando Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    success "Docker Compose v1 disponível"
elif docker compose version >/dev/null 2>&1; then
    success "Docker Compose v2 disponível"
else
    error "Docker Compose não encontrado"
    exit 1
fi

# Teste 3: Verificar estrutura de arquivos
echo "🔍 Verificando estrutura de arquivos..."
required_files=(
    "docker-compose.yml"
    "docker/php84/Dockerfile"
    "docker/php74/Dockerfile" 
    "docker/php56/Dockerfile"
    "nginx/nginx.conf"
    "nginx/templates/php84-http-template.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        success "Arquivo $file encontrado"
    else
        error "Arquivo $file não encontrado"
    fi
done

# Teste 4: Verificar scripts
echo "🔍 Verificando scripts..."
scripts=(
    "scripts/app-create.sh"
    "scripts/app-list.sh"
    "scripts/app-remove.sh"
    "scripts/monitor.sh"
    "scripts/start.sh"
    "scripts/stop.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        success "Script $script OK"
    elif [ -f "$script" ]; then
        warning "Script $script existe mas não é executável"
        chmod +x "$script"
        success "Permissão corrigida para $script"
    else
        error "Script $script não encontrado"
    fi
done

# Teste 5: Verificar se containers estão rodando (se sistema já foi iniciado)
echo "🔍 Verificando containers..."

# Determinar comando do Docker Compose
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    warning "Docker Compose não disponível, pulando verificação"
    COMPOSE_CMD=""
fi

if [ -n "$COMPOSE_CMD" ] && $COMPOSE_CMD ps >/dev/null 2>&1; then
    containers=(
        "nginx-proxy"
        "mysql8"
        "mysql57"
        "app-php84"
        "app-php74"
        "app-php56"
        "redis-cache"
    )
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            success "Container $container está rodando"
        else
            warning "Container $container não está rodando"
        fi
    done
else
    warning "Sistema ainda não foi iniciado (normal se for primeira execução)"
fi

# Teste 6: Verificar diretórios baseado no ambiente
echo "🔍 Verificando diretórios..."

# Detectar ambiente
if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
    # Ambiente de desenvolvimento
    success "Ambiente: DESENVOLVIMENTO"
    
    dev_dirs=(
        "apps"
        "mysql/data"
        "redis/data"
        "logs"
        "nginx/conf.d"
        "nginx/templates"
    )
    
    for dir in "${dev_dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Diretório $dir existe"
        else
            warning "Diretório $dir não existe (execute './scripts/start.sh --setup')"
        fi
    done
    
else
    # Ambiente de produção
    success "Ambiente: PRODUÇÃO"
    
    if [ -d "/sistemas" ]; then
        production_dirs=(
            "/sistemas/apps"
            "/sistemas/mysql8"
            "/sistemas/mysql57"
            "/sistemas/redis"
        )
        
        for dir in "${production_dirs[@]}"; do
            if [ -d "$dir" ]; then
                success "Diretório $dir existe"
            else
                warning "Diretório $dir não existe (execute './scripts/start.sh --setup')"
            fi
        done
    else
        warning "Diretório /sistemas não existe (execute './scripts/start.sh --setup')"
    fi
fi

# Teste 7: Verificar arquivo .env
echo "🔍 Verificando configuração..."
if [ -f ".env" ]; then
    success "Arquivo .env existe"
else
    warning "Arquivo .env não existe (copie de .env.example)"
fi

# Teste 8: Verificar certificados SSL
echo "🔍 Verificando certificados SSL..."
if [ -f "nginx/ssl/cert.pem" ] && [ -f "nginx/ssl/key.pem" ]; then
    success "Certificados SSL encontrados"
else
    warning "Certificados SSL não encontrados (execute generate-ssl.sh)"
fi

# Teste 9: Teste de conectividade (se containers estiverem rodando)
echo "🔍 Testando conectividade..."
if docker ps --format "{{.Names}}" | grep -q "nginx-proxy"; then
    if curl -s -k https://localhost >/dev/null 2>&1; then
        success "Nginx respondendo via HTTPS"
    elif curl -s http://localhost >/dev/null 2>&1; then
        success "Nginx respondendo via HTTP"
    else
        warning "Nginx não está respondendo"
    fi
else
    warning "Container nginx não está rodando"
fi

# Teste 10: Verificar bancos de dados
echo "🔍 Testando bancos de dados..."
if docker ps --format "{{.Names}}" | grep -q "mysql8"; then
    if docker exec mysql8 mysqladmin ping -h localhost >/dev/null 2>&1; then
        success "MySQL 8.0 está respondendo"
    else
        warning "MySQL 8.0 não está respondendo"
    fi
fi

if docker ps --format "{{.Names}}" | grep -q "mysql57"; then
    if docker exec mysql57 mysqladmin ping -h localhost >/dev/null 2>&1; then
        success "MySQL 5.7 está respondendo"
    else
        warning "MySQL 5.7 não está respondendo"
    fi
fi

echo ""
echo "🏁 Teste concluído!"
echo ""
echo "📋 Próximos passos recomendados:"
echo "   1. Se há warnings sobre diretórios: execute './scripts/start.sh --setup'"
echo "   2. Se há warnings sobre containers: execute './scripts/start.sh'"
echo "   3. Para monitoramento: execute './scripts/monitor.sh'"
echo "   4. Para adicionar aplicação: execute './scripts/app-create.sh <php> <nome> <dominio>'"
echo "   5. Para listar aplicações: execute './scripts/app-list.sh'"
