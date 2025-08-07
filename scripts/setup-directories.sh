#!/bin/bash

# Script para preparar a estrutura de diretórios na EC2
# Execute este script ANTES de rodar o docker-compose pela primeira vez

set -e

echo "🚀 Preparando estrutura de diretórios em /sistemas..."

# Criar diretórios base
sudo mkdir -p /sistemas/{apps,mysql8,mysql57,redis,backups,logs}

# Criar subdiretórios para as aplicações
sudo mkdir -p /sistemas/apps/{php81,php74,php56}

# Criar diretórios para bancos de dados
sudo mkdir -p /sistemas/mysql8/{data,conf,logs}
sudo mkdir -p /sistemas/mysql57/{data,conf,logs}

# Criar diretório para Redis
sudo mkdir -p /sistemas/redis/data

# Criar diretórios de logs locais
mkdir -p logs/{nginx,php81,php74,php56}

# Ajustar permissões
sudo chown -R $USER:$USER /sistemas
sudo chmod -R 755 /sistemas

# Configurar auto-start do Docker
sudo systemctl enable docker

echo "✅ Estrutura de diretórios criada com sucesso!"
echo ""
echo "📁 Estrutura criada:"
echo "   /sistemas/apps/php81     - Aplicações PHP 8.1"
echo "   /sistemas/apps/php74     - Aplicações PHP 7.4" 
echo "   /sistemas/apps/php56     - Aplicações PHP 5.6"
echo "   /sistemas/mysql8/data    - Dados MySQL 8.0"
echo "   /sistemas/mysql57/data   - Dados MySQL 5.7"
echo "   /sistemas/redis/data     - Dados Redis"
echo ""
echo "🔧 Próximos passos:"
echo "   1. Coloque suas aplicações nos diretórios correspondentes"
echo "   2. Configure os certificados SSL em nginx/ssl/"
echo "   3. Execute: docker-compose up -d"
