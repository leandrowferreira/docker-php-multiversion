#!/bin/bash

# Script para fazer backup dos bancos de dados
# Uso: ./backup-db.sh [mysql8|mysql57|all]

set -e

BACKUP_DIR="/sistemas/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

backup_mysql8() {
    echo "📦 Fazendo backup do MySQL 8.0..."
    docker exec mysql8 mysqldump -uroot -psistemas_root_2024 --all-databases > "$BACKUP_DIR/mysql8_backup_$DATE.sql"
    gzip "$BACKUP_DIR/mysql8_backup_$DATE.sql"
    echo "✅ Backup MySQL 8.0 concluído: mysql8_backup_$DATE.sql.gz"
}

backup_mysql57() {
    echo "📦 Fazendo backup do MySQL 5.7..."
    docker exec mysql57 mysqldump -uroot -psistemas_root_legacy --all-databases > "$BACKUP_DIR/mysql57_backup_$DATE.sql"
    gzip "$BACKUP_DIR/mysql57_backup_$DATE.sql"
    echo "✅ Backup MySQL 5.7 concluído: mysql57_backup_$DATE.sql.gz"
}

case "${1:-all}" in
    mysql8)
        backup_mysql8
        ;;
    mysql57)
        backup_mysql57
        ;;
    all)
        backup_mysql8
        backup_mysql57
        ;;
    *)
        echo "❌ Uso: $0 [mysql8|mysql57|all]"
        exit 1
        ;;
esac

# Limpar backups antigos (manter apenas os últimos 7 dias)
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo ""
echo "📊 Backups disponíveis:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "Nenhum backup encontrado."
