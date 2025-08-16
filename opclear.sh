#!/bin/bash

# Script rápido para limpar OPcache
# Uso: ./opclear.sh

# Limpar OPcache em todos os containers PHP
for container in app-php84 app-php74 app-php56; do
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        docker exec "$container" php -r "opcache_reset(); echo 'OPcache cleared: $container\n';" 2>/dev/null || echo "Failed: $container"
    else
        echo "Container $container not running"
    fi
done

echo "✅ OPcache refresh completed!"
