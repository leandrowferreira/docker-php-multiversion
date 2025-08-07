# Makefile para gerenciar o sistema de containers

.PHONY: help setup start stop restart status logs monitor backup clean ssl migrate-structure

# Comandos principais
help: ## Mostra esta ajuda
	@echo "Sistema de Containers Laravel Multi-PHP"
	@echo "======================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Prepara o ambiente inicial
	@echo "🚀 Preparando ambiente..."
	chmod +x scripts/*.sh
	./scripts/setup-directories.sh
	cp .env.example .env
	./scripts/generate-ssl.sh
	@echo "✅ Ambiente preparado! Edite o arquivo .env antes de continuar."

setup-letsencrypt: ## Configura Let's Encrypt SSL (usar: make setup-letsencrypt EMAIL=seu@email.com DOMAINS="exemplo.com www.exemplo.com")
	@if [ -z "$(EMAIL)" ] || [ -z "$(DOMAINS)" ]; then \
		echo "❌ Uso: make setup-letsencrypt EMAIL=seu@email.com DOMAINS=\"exemplo.com www.exemplo.com\""; \
		exit 1; \
	fi
	./scripts/setup-letsencrypt.sh -e $(EMAIL) $(DOMAINS)

migrate-structure: ## Migra para nova estrutura de diretórios organizada
	./scripts/migrate-structure.sh

start: ## Inicia todos os containers
	@echo "🚀 Iniciando sistema..."
	docker-compose up -d --build
	@echo "✅ Sistema iniciado!"
	make status

stop: ## Para todos os containers
	@echo "🛑 Parando sistema..."
	docker-compose down
	@echo "✅ Sistema parado!"

restart: ## Reinicia todos os containers
	@echo "🔄 Reiniciando sistema..."
	docker-compose restart
	@echo "✅ Sistema reiniciado!"

status: ## Mostra status dos containers
	@echo "📊 Status dos containers:"
	docker-compose ps

logs: ## Mostra logs de todos os containers
	docker-compose logs --tail=50

monitor: ## Mostra informações detalhadas do sistema
	./scripts/monitor.sh

backup: ## Faz backup dos bancos de dados
	@echo "📦 Fazendo backup..."
	./scripts/backup-db.sh
	@echo "✅ Backup concluído!"

clean: ## Remove containers, volumes e imagens não utilizados
	@echo "🧹 Limpando recursos..."
	docker-compose down --volumes
	docker system prune -f
	@echo "✅ Limpeza concluída!"

# Comandos para serviços específicos
logs-nginx: ## Logs do Nginx
	docker-compose logs nginx

logs-mysql8: ## Logs do MySQL 8.0
	docker-compose logs mysql8

logs-mysql57: ## Logs do MySQL 5.7
	docker-compose logs mysql57

logs-php81: ## Logs do PHP 8.1
	docker-compose logs app-php81

logs-php74: ## Logs do PHP 7.4
	docker-compose logs app-php74

logs-php56: ## Logs do PHP 5.6
	docker-compose logs app-php56

# Comandos de manutenção
restart-nginx: ## Reinicia apenas o Nginx
	docker-compose restart nginx

restart-mysql8: ## Reinicia apenas o MySQL 8.0
	docker-compose restart mysql8

restart-mysql57: ## Reinicia apenas o MySQL 5.7
	docker-compose restart mysql57

# Comandos de desenvolvimento
shell-php81: ## Entra no container PHP 8.1
	docker exec -it laravel-php81 bash

shell-php74: ## Entra no container PHP 7.4
	docker exec -it laravel-php74 bash

shell-php56: ## Entra no container PHP 5.6
	docker exec -it laravel-php56 bash

shell-mysql8: ## Entra no MySQL 8.0
	docker exec -it mysql8 mysql -uroot -p

shell-mysql57: ## Entra no MySQL 5.7
	docker exec -it mysql57 mysql -uroot -p

# Auto-start
autostart: ## Configura auto-start do sistema
	./scripts/setup-autostart.sh

# Adicionar aplicação com suporte a domínios e subdomínios
add-app: ## Adiciona nova aplicação (usar: make add-app APP=nome PHP=php81 DOMAIN=exemplo.com [WWW=true])
	@if [ -z "$(APP)" ] || [ -z "$(PHP)" ] || [ -z "$(DOMAIN)" ]; then \
		echo "❌ Uso: make add-app APP=nome PHP=php81 DOMAIN=exemplo.com"; \
		echo "   Versões PHP: php81, php74, php56"; \
		echo "   Opções: WWW=true para incluir www"; \
		exit 1; \
	fi
	@if [ "$(WWW)" = "true" ]; then \
		./scripts/add-app.sh $(APP) $(PHP) $(DOMAIN) --www; \
	else \
		./scripts/add-app.sh $(APP) $(PHP) $(DOMAIN); \
	fi

# Comandos de informação
info: ## Mostra informações do sistema
	@echo "📋 Informações do Sistema"
	@echo "========================"
	@echo "Containers ativos:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(nginx|mysql|laravel|redis)"
	@echo ""
	@echo "Redes Docker:"
	@docker network ls | grep sistemas
	@echo ""
	@echo "Volumes de dados:"
	@echo "  MySQL 8.0: $$(du -sh /sistemas/mysql8/data 2>/dev/null || echo 'N/A')"
	@echo "  MySQL 5.7: $$(du -sh /sistemas/mysql57/data 2>/dev/null || echo 'N/A')"
	@echo "  Redis: $$(du -sh /sistemas/redis/data 2>/dev/null || echo 'N/A')"
