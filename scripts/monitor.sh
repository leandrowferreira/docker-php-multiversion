#!/bin/bash

# Script de monitoramento dos containers
# Mostra status, uso de recursos e logs recentes

set -e

# Função para detectar ambiente
detect_environment() {
    # Verificar se estamos usando docker-compose.dev.yml
    if [ -f "docker-compose.dev.yml" ] && docker compose -f docker-compose.yml -f docker-compose.dev.yml ps >/dev/null 2>&1; then
        export ENV_TYPE="development"
        echo "🔧 Ambiente detectado: DESENVOLVIMENTO"
    else
        export ENV_TYPE="production"
        echo "🏭 Ambiente detectado: PRODUÇÃO"
    fi
}

# Detectar ambiente
detect_environment

echo ""
echo "🐳 Status dos Containers"
echo "========================"

if [ "$ENV_TYPE" = "development" ]; then
    docker compose -f docker-compose.yml -f docker-compose.dev.yml ps --format "table {{.Name}}\t{{.Service}}\t{{.Status}}"
else
    docker compose -f docker-compose.yml ps --format "table {{.Name}}\t{{.Service}}\t{{.Status}}"
fi

echo ""
echo "📊 Uso de Recursos"
echo "=================="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "💾 Uso de Disco - Volumes"
echo "=========================="

if [ "$ENV_TYPE" = "development" ]; then
    echo "MySQL 8.0:"
    if docker exec mysql8 du -sh /var/lib/mysql 2>/dev/null; then
        :  # Comando executado com sucesso, não adicionar mensagem extra
    elif [ -d "./mysql/data/mysql8" ]; then
        echo "  Diretório existe (sem acesso para calcular tamanho)"
    else
        echo "  Diretório não encontrado"
    fi

    echo "MySQL 5.7:"
    if docker exec mysql57 du -sh /var/lib/mysql 2>/dev/null; then
        :  # Comando executado com sucesso, não adicionar mensagem extra
    elif [ -d "./mysql/data/mysql57" ]; then
        echo "  Diretório existe (sem acesso para calcular tamanho)"
    else
        echo "  Diretório não encontrado"
    fi

    echo "Redis:"
    if docker exec redis-cache du -sh /data 2>/dev/null; then
        :  # Comando executado com sucesso, não adicionar mensagem extra
    elif [ -d "./redis/data" ]; then
        du -sh ./redis/data
    else
        echo "  Diretório não encontrado"
    fi

    echo "Aplicações:"
    if ls ./apps/* >/dev/null 2>&1; then
        du -sh ./apps/*
    else
        echo "  Nenhuma aplicação encontrada"
    fi
else
    echo "MySQL 8.0:"
    if [ -d "/sistemas/mysql8/data" ]; then
        du -sh /sistemas/mysql8/data
    else
        echo "  Diretório não encontrado"
    fi

    echo "MySQL 5.7:"
    if [ -d "/sistemas/mysql57/data" ]; then
        du -sh /sistemas/mysql57/data
    else
        echo "  Diretório não encontrado"
    fi

    echo "Redis:"
    if [ -d "/sistemas/redis/data" ]; then
        du -sh /sistemas/redis/data
    else
        echo "  Diretório não encontrado"
    fi

    echo "Aplicações:"
    if ls /sistemas/apps/* >/dev/null 2>&1; then
        du -sh /sistemas/apps/*
    else
        echo "  Nenhuma aplicação encontrada"
    fi
fi

echo ""
echo "🌐 Conexões de Rede"
echo "==================="
docker network ls | grep sistemas

echo ""
echo "🔄 Para mais detalhes:"
if [ "$ENV_TYPE" = "development" ]; then
    echo "  docker compose -f docker-compose.yml -f docker-compose.dev.yml logs [serviço]"
    echo "  docker exec -it [container] bash"
    echo "  docker compose -f docker-compose.yml -f docker-compose.dev.yml restart [serviço]"
else
    echo "  docker compose logs [serviço]"
    echo "  docker exec -it [container] bash"
    echo "  docker compose restart [serviço]"
fi