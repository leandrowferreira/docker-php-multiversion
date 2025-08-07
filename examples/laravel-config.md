# Exemplos de Configuração para Aplicações Laravel

## 1. Configuração do .env para Laravel

```env
APP_NAME="Minha Aplicação"
APP_ENV=production
APP_KEY=base64:GERAR_COM_ARTISAN_KEY_GENERATE
APP_DEBUG=false
APP_URL=https://app.exemplo.com

LOG_CHANNEL=stack
LOG_LEVEL=error

# Configuração do banco de dados
DB_CONNECTION=mysql
DB_HOST=mysql8
DB_PORT=3306
DB_DATABASE=sistemas_db
DB_USERNAME=sistemas_user
DB_PASSWORD=sistemas_pass

# Cache e sessões via Redis
BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Email (configurar conforme necessário)
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@exemplo.com"
MAIL_FROM_NAME="${APP_NAME}"
```

## 2. Configuração para aplicação PHP 5.6 (Laravel 5.x)

```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=GERAR_CHAVE_32_CARACTERES
APP_URL=https://legado.exemplo.com

# Banco de dados MySQL 5.7
DB_HOST=mysql57
DB_DATABASE=sistemas_legacy_db
DB_USERNAME=sistemas_legacy_user
DB_PASSWORD=sistemas_legacy_pass

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync
```

## 3. Script de Deploy Simples

```bash
#!/bin/bash
# deploy-app.sh

APP_NAME=$1
PHP_VERSION=$2
GIT_REPO=$3

if [ $# -ne 3 ]; then
    echo "Uso: $0 <nome-app> <php-version> <git-repo>"
    exit 1
fi

APP_DIR="/sistemas/apps/$PHP_VERSION/$APP_NAME"

# Criar diretório se não existir
mkdir -p "$APP_DIR"

# Fazer deploy via Git
cd "$APP_DIR"
git clone "$GIT_REPO" .

# Instalar dependências
docker exec "laravel-$PHP_VERSION" bash -c "cd /var/www/html/$APP_NAME && composer install --no-dev --optimize-autoloader"

# Configurar aplicação
docker exec "laravel-$PHP_VERSION" bash -c "cd /var/www/html/$APP_NAME && php artisan key:generate"
docker exec "laravel-$PHP_VERSION" bash -c "cd /var/www/html/$APP_NAME && php artisan migrate --force"
docker exec "laravel-$PHP_VERSION" bash -c "cd /var/www/html/$APP_NAME && php artisan config:cache"
docker exec "laravel-$PHP_VERSION" bash -c "cd /var/www/html/$APP_NAME && php artisan route:cache"

echo "Deploy concluído para $APP_NAME"
```

## 4. Estrutura recomendada para aplicação Laravel

```
/sistemas/apps/php84/minha-app/
├── app/
├── bootstrap/
├── config/
├── database/
├── public/              # Document root no Nginx
│   ├── index.php       # Entry point
│   ├── css/
│   ├── js/
│   └── images/
├── resources/
├── routes/
├── storage/
│   ├── app/
│   ├── framework/
│   └── logs/
├── vendor/             # Dependências Composer
├── .env                # Configurações específicas
├── composer.json
└── artisan
```

## 5. Comandos úteis para manutenção

```bash
# Limpar cache da aplicação
docker exec laravel-php84 bash -c "cd /var/www/html/minha-app && php artisan cache:clear"

# Executar migrações
docker exec laravel-php84 bash -c "cd /var/www/html/minha-app && php artisan migrate"

# Ver logs da aplicação
docker exec laravel-php84 bash -c "tail -f /var/www/html/minha-app/storage/logs/laravel.log"

# Executar comandos Artisan
docker exec laravel-php84 bash -c "cd /var/www/html/minha-app && php artisan comando"
```

## 6. Backup de aplicação específica

```bash
#!/bin/bash
# backup-app.sh

APP_NAME=$1
BACKUP_DIR="/sistemas/backups/apps"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup do código
tar -czf "$BACKUP_DIR/${APP_NAME}_code_${DATE}.tar.gz" -C "/sistemas/apps" "$APP_NAME"

# Backup do banco (se aplicação tiver banco específico)
# docker exec mysql8 mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} ${APP_DATABASE} > "$BACKUP_DIR/${APP_NAME}_db_${DATE}.sql"

echo "Backup da aplicação $APP_NAME concluído"
```
