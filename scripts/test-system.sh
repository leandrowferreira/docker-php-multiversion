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
    success "Docker Compose disponível"
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
    "nginx/conf.d/app-php84.conf"
    ".env.example"
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
    "scripts/setup-directories.sh"
    "scripts/add-app.sh"
    "scripts/generate-ssl.sh"
    "scripts/backup-db.sh"
    "scripts/monitor.sh"
    "scripts/setup-autostart.sh"
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
if docker-compose ps >/dev/null 2>&1; then
    containers=(
        "nginx-proxy"
        "mysql8"
        "mysql57"
        "laravel-php84"
        "laravel-php74"
        "laravel-php56"
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

# Teste 6: Verificar diretórios de produção (se existirem)
echo "🔍 Verificando diretórios de produção..."
if [ -d "/sistemas" ]; then
    production_dirs=(
        "/sistemas/apps"
        "/sistemas/mysql8"
        "/sistemas/mysql57"
        "/sistemas/redis"
        "/sistemas/backups"
    )
    
    for dir in "${production_dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Diretório $dir existe"
        else
            warning "Diretório $dir não existe (execute setup-directories.sh)"
        fi
    done
else
    warning "Diretório /sistemas não existe (execute setup-directories.sh)"
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
echo "   1. Se há warnings sobre diretórios: execute 'make setup'"
echo "   2. Se há warnings sobre containers: execute 'make start'"
echo "   3. Para monitoramento: execute 'make monitor'"
echo "   4. Para adicionar aplicação: execute 'make add-app APP=nome PHP=php84 DOMAIN=exemplo.com'"
