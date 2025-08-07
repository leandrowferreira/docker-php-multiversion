#!/bin/bash

# Script de monitoramento dos containers
# Mostra status, uso de recursos e logs recentes

set -e

echo "🐳 Status dos Containers"
echo "========================"
docker-compose ps

echo ""
echo "📊 Uso de Recursos"
echo "=================="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo ""
echo "💾 Uso de Disco - Volumes"
echo "=========================="
echo "MySQL 8.0:"
du -sh /sistemas/mysql8/data 2>/dev/null || echo "  Diretório não encontrado"

echo "MySQL 5.7:"
du -sh /sistemas/mysql57/data 2>/dev/null || echo "  Diretório não encontrado"

echo "Redis:"
du -sh /sistemas/redis/data 2>/dev/null || echo "  Diretório não encontrado"

echo "Aplicações:"
du -sh /sistemas/apps/* 2>/dev/null || echo "  Nenhuma aplicação encontrada"

echo ""
echo "🔍 Logs Recentes (últimas 5 linhas)"
echo "===================================="

for container in nginx-proxy mysql8 mysql57 laravel-php81 laravel-php74 laravel-php56; do
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        echo "--- $container ---"
        docker logs --tail 5 "$container" 2>/dev/null || echo "Sem logs disponíveis"
        echo ""
    fi
done

echo "🌐 Conexões de Rede"
echo "==================="
docker network ls | grep sistemas

echo ""
echo "🔄 Para mais detalhes:"
echo "  docker-compose logs [serviço]   - Ver logs completos"
echo "  docker exec -it [container] bash - Entrar no container"
echo "  docker-compose restart [serviço] - Reiniciar serviço"
