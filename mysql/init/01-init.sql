-- =====================================================
-- Docker PHP Multiversion - Script de Inicialização MySQL 8.0
-- =====================================================
-- Este script será executado automaticamente na primeira inicialização
-- do container MySQL 8.0. As configurações refletem o .env.example
--

-- =====================================================
-- USUÁRIOS E PRIVILÉGIOS
-- =====================================================

-- O usuário principal já é criado automaticamente pelas variáveis de ambiente:
-- MYSQL_USER=app_user
-- MYSQL_PASSWORD=apppass123
-- MYSQL_DATABASE=app_database

-- Criar usuários adicionais se necessário (descomente conforme necessidade)
-- CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'readonly_pass';
-- GRANT SELECT ON app_database.* TO 'readonly_user'@'%';

-- Usuário para backups (descomente se necessário)
-- CREATE USER 'backup_user'@'%' IDENTIFIED BY 'backup_pass';
-- GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON app_database.* TO 'backup_user'@'%';

-- =====================================================
-- CONFIGURAÇÕES DE PERFORMANCE
-- =====================================================

-- Buffer pool MySQL (128MB - conforme .env.example)
SET GLOBAL innodb_buffer_pool_size = 134217728;

-- Tamanho do log InnoDB (64MB)
SET GLOBAL innodb_log_file_size = 67108864;

-- Máximo de conexões (conforme .env.example)
SET GLOBAL max_connections = 50;

-- Configurações adicionais de performance
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL innodb_file_per_table = 1;
SET GLOBAL query_cache_type = 1;
SET GLOBAL query_cache_size = 16777216; -- 16MB

-- =====================================================
-- CONFIGURAÇÕES REGIONAIS
-- =====================================================

-- Timezone Brasil (conforme .env.example TZ=America/Sao_Paulo)
SET GLOBAL time_zone = '-03:00';

-- Charset padrão UTF-8
SET GLOBAL character_set_server = 'utf8mb4';
SET GLOBAL collation_server = 'utf8mb4_unicode_ci';

-- =====================================================
-- CONFIGURAÇÕES DE SEGURANÇA
-- =====================================================

-- Aplicar todas as mudanças
FLUSH PRIVILEGES;

-- Log de inicialização
SELECT 'Docker PHP Multiversion - MySQL 8.0 inicializado com sucesso!' AS Status;
