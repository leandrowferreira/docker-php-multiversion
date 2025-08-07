#!/bin/bash

# Script para reorganizar a estrutura de diretórios conforme nova proposta
# Migra da estrutura atual para a estrutura melhorada

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

echo "🔄 Reorganizando estrutura de diretórios"
echo "======================================="

# Verificar se /sistemas existe
if [ ! -d "/sistemas" ]; then
    error "Diretório /sistemas não existe. Execute primeiro: scripts/setup-directories.sh"
    exit 1
fi

# Fazer backup da estrutura atual
BACKUP_DIR="/sistemas/backup-$(date +%Y%m%d_%H%M%S)"
info "Criando backup da estrutura atual: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

# Listar estrutura atual
info "Estrutura atual de /sistemas:"
ls -la /sistemas/ || true

echo ""
warning "Esta operação irá reorganizar a estrutura de diretórios."
warning "Um backup será criado em: $BACKUP_DIR"
echo ""
read -p "Deseja continuar? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Operação cancelada."
    exit 0
fi

# Criar nova estrutura de diretórios
info "Criando nova estrutura..."

# 1. Diretório do projeto Docker
sudo mkdir -p /sistemas/docker-containers
success "Criado: /sistemas/docker-containers"

# 2. Aplicações (manter estrutura por PHP)
sudo mkdir -p /sistemas/apps/{php84,php74,php56}
success "Criado: /sistemas/apps/"

# 3. Bancos de dados reorganizados
sudo mkdir -p /sistemas/databases/mysql8/{data,conf,logs}
sudo mkdir -p /sistemas/databases/mysql57/{data,conf,logs}
success "Criado: /sistemas/databases/"

# 4. Cache
sudo mkdir -p /sistemas/cache/redis/data
success "Criado: /sistemas/cache/"

# 5. Backups organizados
sudo mkdir -p /sistemas/backups/{daily,weekly,monthly,apps}
success "Criado: /sistemas/backups/"

# 6. SSL e certificados
sudo mkdir -p /sistemas/ssl/{letsencrypt,domains,temp}
success "Criado: /sistemas/ssl/"

# 7. Logs centralizados
sudo mkdir -p /sistemas/logs/{nginx,php,mysql,system}
success "Criado: /sistemas/logs/"

# Migrar dados existentes se houver
info "Migrando dados existentes..."

# Migrar MySQL 8
if [ -d "/sistemas/mysql8" ]; then
    info "Migrando dados MySQL 8.0..."
    sudo cp -R /sistemas/mysql8/* /sistemas/databases/mysql8/ 2>/dev/null || true
    sudo mv /sistemas/mysql8 "$BACKUP_DIR/" 2>/dev/null || true
    success "MySQL 8.0 migrado"
fi

# Migrar MySQL 5.7
if [ -d "/sistemas/mysql57" ]; then
    info "Migrando dados MySQL 5.7..."
    sudo cp -R /sistemas/mysql57/* /sistemas/databases/mysql57/ 2>/dev/null || true
    sudo mv /sistemas/mysql57 "$BACKUP_DIR/" 2>/dev/null || true
    success "MySQL 5.7 migrado"
fi

# Migrar Redis
if [ -d "/sistemas/redis" ]; then
    info "Migrando dados Redis..."
    sudo cp -R /sistemas/redis/* /sistemas/cache/redis/ 2>/dev/null || true
    sudo mv /sistemas/redis "$BACKUP_DIR/" 2>/dev/null || true
    success "Redis migrado"
fi

# Migrar aplicações (se existirem)
if [ -d "/sistemas/apps" ]; then
    info "Aplicações já estão na estrutura correta"
else
    success "Estrutura de aplicações criada"
fi

# Migrar backups
if [ -d "/sistemas/backups" ] && [ "$(ls -A /sistemas/backups 2>/dev/null)" ]; then
    info "Organizando backups existentes..."
    sudo mv /sistemas/backups/* /sistemas/backups/daily/ 2>/dev/null || true
    success "Backups reorganizados"
fi

# Copiar projeto Docker para nova localização
info "Copiando projeto Docker para /sistemas/docker-containers..."
sudo cp -R "$(pwd)"/* /sistemas/docker-containers/ 2>/dev/null || true
sudo chown -R $USER:$USER /sistemas/docker-containers/
success "Projeto Docker copiado"

# Ajustar permissões
info "Ajustando permissões..."
sudo chown -R $USER:$USER /sistemas/
sudo chmod -R 755 /sistemas/
success "Permissões ajustadas"

# Atualizar docker-compose.yml para nova estrutura
info "Atualizando configurações do Docker Compose..."

# Criar novo docker-compose.yml com paths atualizados
cat > /sistemas/docker-containers/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - /sistemas/ssl:/etc/nginx/ssl
      - /sistemas/logs/nginx:/var/log/nginx
    depends_on:
      - app-php84
      - app-php74
      - app-php56
    networks:
      - sistemas-network
    restart: unless-stopped

  # MySQL 8.0 (Versão mais recente)
  mysql8:
    image: mysql:8.0
    container_name: mysql8
    environment:
      MYSQL_ROOT_PASSWORD: sistemas_root_2024
      MYSQL_DATABASE: sistemas_db
      MYSQL_USER: sistemas_user
      MYSQL_PASSWORD: sistemas_pass
    volumes:
      - /sistemas/databases/mysql8/data:/var/lib/mysql
      - /sistemas/databases/mysql8/conf:/etc/mysql/conf.d
      - /sistemas/logs/mysql:/var/log/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - sistemas-network
    restart: unless-stopped
    command: --default-authentication-plugin=mysql_native_password

  # MySQL 5.7 (Versão legada)
  mysql57:
    image: mysql:5.7
    container_name: mysql57
    environment:
      MYSQL_ROOT_PASSWORD: sistemas_root_legacy
      MYSQL_DATABASE: sistemas_legacy_db
      MYSQL_USER: sistemas_legacy_user
      MYSQL_PASSWORD: sistemas_legacy_pass
    volumes:
      - /sistemas/databases/mysql57/data:/var/lib/mysql
      - /sistemas/databases/mysql57/conf:/etc/mysql/conf.d
      - /sistemas/logs/mysql:/var/log/mysql
    ports:
      - "3307:3306"
    networks:
      - sistemas-network
    restart: unless-stopped

  # Aplicação Laravel com PHP 8.4
  app-php84:
    build:
      context: ./docker/php84
      dockerfile: Dockerfile
    container_name: laravel-php84
    volumes:
      - /sistemas/apps/php84:/var/www/html
      - /sistemas/logs/php:/var/log/php
    depends_on:
      - mysql8
    networks:
      - sistemas-network
    restart: unless-stopped
    environment:
      - PHP_VERSION=8.4

  # Aplicação Laravel com PHP 7.4
  app-php74:
    build:
      context: ./docker/php74
      dockerfile: Dockerfile
    container_name: laravel-php74
    volumes:
      - /sistemas/apps/php74:/var/www/html
      - /sistemas/logs/php:/var/log/php
    depends_on:
      - mysql8
    networks:
      - sistemas-network
    restart: unless-stopped
    environment:
      - PHP_VERSION=7.4

  # Aplicação Laravel com PHP 5.6 (Legado)
  app-php56:
    build:
      context: ./docker/php56
      dockerfile: Dockerfile
    container_name: laravel-php56
    volumes:
      - /sistemas/apps/php56:/var/www/html
      - /sistemas/logs/php:/var/log/php
    depends_on:
      - mysql57
    networks:
      - sistemas-network
    restart: unless-stopped
    environment:
      - PHP_VERSION=5.6

  # Redis para cache (opcional, mas recomendado para Laravel)
  redis:
    image: redis:7-alpine
    container_name: redis-cache
    ports:
      - "6379:6379"
    volumes:
      - /sistemas/cache/redis/data:/data
    networks:
      - sistemas-network
    restart: unless-stopped

networks:
  sistemas-network:
    driver: bridge
    name: sistemas-network
EOF

success "Docker Compose atualizado"

# Mostrar nova estrutura
echo ""
info "🎉 Reorganização concluída!"
echo ""
info "📁 Nova estrutura de /sistemas:"
echo "📂 /sistemas/"
echo "├── 🐳 docker-containers/     # Projeto Docker (códigos, scripts, configs)"
echo "├── 📱 apps/                  # Aplicações por versão PHP"
echo "│   ├── php84/"
echo "│   ├── php74/"
echo "│   └── php56/"
echo "├── 🗄️  databases/             # Dados dos bancos"
echo "│   ├── mysql8/"
echo "│   └── mysql57/"
echo "├── 💾 cache/                 # Cache e sessões"
echo "│   └── redis/"
echo "├── 💽 backups/               # Backups organizados"
echo "│   ├── daily/"
echo "│   ├── weekly/"
echo "│   ├── monthly/"
echo "│   └── apps/"
echo "├── 🔐 ssl/                   # Certificados SSL"
echo "│   ├── letsencrypt/"
echo "│   ├── domains/"
echo "│   └── temp/"
echo "└── 📊 logs/                  # Logs centralizados"
echo "    ├── nginx/"
echo "    ├── php/"
echo "    ├── mysql/"
echo "    └── system/"

echo ""
warning "⚠️  IMPORTANTE:"
echo "   1. O projeto Docker agora está em: /sistemas/docker-containers/"
echo "   2. Execute os comandos a partir deste diretório:"
echo "      cd /sistemas/docker-containers/"
echo "      make start"
echo ""
echo "   3. Backup da estrutura anterior: $BACKUP_DIR"
echo "   4. Verifique se tudo está funcionando antes de remover o backup"

echo ""
success "✅ Estrutura reorganizada com sucesso!"
