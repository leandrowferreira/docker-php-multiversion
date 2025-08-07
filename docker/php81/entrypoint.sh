#!/bin/bash
set -e

# Criar diretórios de log se não existirem
mkdir -p /var/log/php

# Ajustar permissões
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/log/php

# Se existir composer.json, instalar dependências
if [ -f "/var/www/html/composer.json" ]; then
    echo "Instalando dependências do Composer..."
    cd /var/www/html
    composer install --no-dev --optimize-autoloader
fi

# Se existir .env.example e não existir .env, copiar
if [ -f "/var/www/html/.env.example" ] && [ ! -f "/var/www/html/.env" ]; then
    echo "Copiando .env.example para .env..."
    cp /var/www/html/.env.example /var/www/html/.env
fi

# Se for Laravel, gerar chave se necessário
if [ -f "/var/www/html/artisan" ] && [ ! -s "/var/www/html/.env" ]; then
    echo "Gerando chave da aplicação Laravel..."
    cd /var/www/html
    php artisan key:generate --no-interaction
fi

# Executar migrações se existirem
if [ -f "/var/www/html/artisan" ]; then
    echo "Executando migrações..."
    cd /var/www/html
    php artisan migrate --force || true
fi

# Iniciar PHP-FPM
echo "Iniciando PHP-FPM..."
exec php-fpm
