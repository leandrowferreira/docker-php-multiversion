# Docker PHP Multiversion

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg?logo=docker)](https://www.docker.com/)
[![PHP](https://img.shields.io/badge/PHP-5.6%20|%207.4%20|%208.4-777BB4.svg?logo=php)](https://www.php.net/)
[![Nginx](https://img.shields.io/badge/Nginx-1.25+-green.svg?logo=nginx)](https://nginx.org/)
[![MySQL](https://img.shields.io/badge/MySQL-5.7%20|%208.0-4479A1.svg?logo=mysql)](https://www.mysql.com/)
[![Redis](https://img.shields.io/badge/Redis-7.0+-DC382D.svg?logo=redis)](https://redis.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/leandrowferreira/docker-php-multiversion/graphs/commit-activity)

Sistema Docker completo para desenvolvimento e produção com suporte simultâneo a múltiplas versões PHP, automação de deploy e gerenciamento unificado de aplicações.

## 📑 Sumário

- [💡 Motivação e Contexto](#-motivação-e-contexto)
  - [🎯 Problema Original](#-problema-original)
  - [✨ Solução Implementada](#-solução-implementada)
  - [🏢 Casos de Uso Reais](#-casos-de-uso-reais)
  - [🆚 Comparação com Outras Soluções](#-comparação-com-outras-soluções)
- [🚀 Características Principais](#-características-principais)
- [🛠️ Stack Tecnológica](#️-stack-tecnológica)
- [📋 Pré-requisitos](#-pré-requisitos)
  - [Sistema Operacional](#sistema-operacional)
  - [Software Necessário](#software-necessário)
  - [Verificação do Sistema](#verificação-do-sistema)
  - [Portas Necessárias](#portas-necessárias)
- [⚡ Instalação e Uso Rápido](#-instalação-e-uso-rápido)
  - [🔍 Detecção Automática de Ambiente](#-como-funciona-a-detecção-automática-de-ambiente)
- [� Criando uma Aplicação Laravel](#-criando-uma-aplicação-laravel)
- [�📋 Comandos Disponíveis](#-comandos-disponíveis)
  - [Gerenciamento do Sistema](#gerenciamento-do-sistema)
  - [Gerenciamento de Aplicações](#gerenciamento-de-aplicações)
  - [Exemplos Práticos](#exemplos-práticos)
- [🏗️ Estrutura do Projeto](#️-estrutura-do-projeto)
- [🌍 Ambientes](#-ambientes)
  - [Detecção Automática](#detecção-automática)
  - [Desenvolvimento](#desenvolvimento)
  - [Produção](#produção)
  - [🔄 Autostart em Produção](#-autostart-em-produção)
- [⚙️ Configuração](#️-configuração)
  - [Variáveis de Ambiente (.env)](#variáveis-de-ambiente-env)
  - [🔄 Aplicando Alterações no .env](#-aplicando-alterações-no-env)
  - [Principais Configurações](#principais-configurações)
- [📊 Monitoramento e Logs](#-monitoramento-e-logs)
- [🔒 SSL e Segurança](#-ssl-e-segurança)
  - [Comportamento de Domínios](#comportamento-de-domínios)
  - [🔐 Geração de Certificados SSL Automática](#-geração-de-certificados-ssl-automática)
  - [🔄 Renovação Automática de Certificados](#-renovação-automática-de-certificados)
  - [📋 Arquitetura SSL do Sistema](#-arquitetura-ssl-do-sistema)
  - [🛡️ Configurações de Segurança SSL](#️-configurações-de-segurança-ssl)
  - [🚨 Troubleshooting SSL](#-troubleshooting-ssl)
  - [⚡ Configuração SSL Rápida](#-configuração-ssl-rápida)
- [🎯 Exemplos Práticos](#-exemplos-práticos)
- [📈 Performance](#-performance)
- [🤝 Contribuição](#-contribuição)
- [📝 Changelog](#-changelog)
- [🆘 Suporte](#-suporte)
- [📄 Licença](#-licença)
- [🙏 Agradecimentos](#-agradecimentos)

---

## 💡 Motivação e Contexto

Este projeto nasceu da necessidade de **deploy rápido e eficiente de aplicações PHP** em instâncias EC2 de prototipação. O cenário típico envolvia:

### 🎯 **Problema Original**
- **Deploy demorado**: Configurar ambiente PHP, MySQL, Nginx para cada nova aplicação
- **Conflitos de versão**: Aplicações legadas em PHP 5.6 convivendo com novas em PHP 8.4
- **Configuração repetitiva**: Nginx virtual hosts, certificados SSL, bancos de dados
- **Ambiente inconsistente**: Diferenças entre desenvolvimento local e produção

### ✨ **Solução Implementada**
- **Deploy em 30 segundos**: Um comando cria aplicação completa com domínio configurado
- **Múltiplas versões simultâneas**: PHP 5.6, 7.4 e 8.4 rodando em paralelo
- **Zero configuração manual**: SSL, virtual hosts e bancos criados automaticamente
- **Ambientes idênticos**: Mesmo comportamento em desenvolvimento e produção

### 🏢 **Casos de Uso Reais**
- **🔄 Migração gradual**: Manter sistema legado (PHP 5.6) enquanto desenvolve novo (PHP 8.4)
- **👨‍💻 Prototipação rápida**: Clientes precisam ver demo funcionando em minutos
- **🧪 Testes de compatibilidade**: Testar mesma aplicação em diferentes versões PHP
- **📊 Ambiente multi-cliente**: Cada cliente com sua aplicação isolada e versão PHP ideal

### 🆚 **Comparação com Outras Soluções**

| Solução | ⏱️ Setup | 🐘 Multi-PHP | 🔄 Deploy | 🛠️ Manutenção | 🎯 Cenário Ideal |
|---------|----------|-------------|-----------|---------------|------------------|
| **Docker PHP Multiversion** | 30 segundos | ✅ Nativo | Um comando | Zero | **Prototipação EC2** |
| XAMPP/WAMP | 10 minutos | ❌ Uma versão | Manual | Alta | Desenvolvimento local |
| Vagrant + VirtualBox | 20 minutos | ✅ Configurável | Lento | Média | Desenvolvimento isolado |
| Docker Compose Manual | 60+ minutos | ❌ Por projeto | Manual | Alta | Projetos únicos |
| Kubernetes + Helm | 4+ horas | ✅ Complexo | Automático | Muito alta | Produção enterprise |
| Laravel Sail | 5 minutos | ❌ Uma versão | Específico | Baixa | Projetos Laravel |
| Devilbox | 15 minutos | ✅ Limitado | Manual | Média | Desenvolvimento local |

**🎯 Por que esta solução é superior para EC2 de prototipação:**

- **⚡ Velocidade**: Deploy em 30s vs 60+ minutos de configuração manual
- **🔧 Zero dependência**: Não precisa de Vagrant, VirtualBox ou Kubernetes
- **💰 Custo-efetivo**: Uma instância EC2 roda múltiplas aplicações PHP
- **🎨 Cliente-ready**: URLs diretas com SSL automático para demonstrações
- **🔄 Migração amigável**: Mantém sistemas legacy enquanto desenvolve novos
- **📦 Produção-ready**: Mesmo ambiente em dev/staging/produção

## 🚀 Características Principais

- **🐘 Múltiplas versões PHP**: Suporte simultâneo a PHP 5.6, 7.4 e 8.4
- **⚡ Deploy automatizado**: Criação de aplicações com um comando
- **🔄 Detecção de ambiente**: Automática entre desenvolvimento e produção
- **🎯 Framework agnóstico**: Suporte a Laravel, CakePHP e qualquer framework PHP
- **📦 Stack completa**: Nginx, MySQL (5.7/8.0), Redis e PHPMyAdmin inclusos
- **🔒 SSL automático**: Configuração Let's Encrypt integrada
- **�️ Segurança por design**: Domínios não configurados retornam 404 automaticamente
- **�📊 Monitoramento**: Scripts de status e logs em tempo real
- **🛠️ Zero configuração**: Funciona out-of-the-box

## 🛠️ Stack Tecnológica

| Componente | Versão | Portas | Descrição |
|------------|--------|--------|-----------|
| **Nginx** | Alpine | 80, 443 | Proxy reverso e servidor web com configuração padrão que retorna 404 para domínios não mapeados |
| **PHP-FPM** | 5.6, 7.4, 8.4 | 9000 | Processamento PHP simultâneo |
| **MySQL** | 5.7, 8.0 | 3306, 3307 | Bancos de dados |
| **Redis** | 7-Alpine | 6379 | Cache e sessões |
| **PHPMyAdmin** | Latest | 8080 | Administração MySQL |

## 📋 Pré-requisitos

### Sistema Operacional
- **Linux** (Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+)
- **Arquitetura**: x86_64 (AMD64)

### Software Necessário

#### 1. Docker Engine (20.10+)
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# CentOS/RHEL
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### 2. Docker Compose (2.0+)
```bash
# Já incluído no Docker Engine moderno
# Verificar instalação (use 'docker compose' - comando integrado)
docker compose version
```
**📝 Nota:** Use `docker compose` (com espaço) em vez de `docker-compose` (hífen). O comando integrado é a versão moderna.

#### 3. Git (apenas para instalação)
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y git

# CentOS/RHEL
sudo yum install -y git
```
**📝 Nota:** Git é necessário apenas para clonar o repositório. Depois da instalação não é mais usado pelo sistema.

### Verificação do Sistema
```bash
# Verificar se todos os pré-requisitos estão instalados
docker --version          # Docker 20.10+
docker compose version    # Docker Compose 2.0+

# Git (apenas para instalação inicial)
git --version             # Git 2.25+

# Testar Docker sem sudo
docker run hello-world
```

### Portas Necessárias
O sistema precisa que estas portas estejam **livres** (não sendo usadas por outros serviços):

- **80** (HTTP) - Servidor web Nginx
- **443** (HTTPS) - Servidor web Nginx com SSL
- **3306** (MySQL 8.0) - Banco de dados principal
- **3307** (MySQL 5.7) - Banco de dados legado
- **6379** (Redis) - Cache e sessões
- **8080** (PHPMyAdmin) - Interface de administração MySQL

```bash
# Verificar se alguma porta está em uso (deve retornar vazio se livres)
sudo netstat -tulpn | grep -E ':(80|443|3306|3307|6379|8080)\s'

# Se alguma porta estiver em uso, você verá algo como:
# tcp 0.0.0.0:80 0.0.0.0:* LISTEN 1234/apache2
```

**🔧 Se houver conflitos de portas:**
```bash
# Pare o serviço conflitante (exemplo com Apache na porta 80)
sudo systemctl stop apache2
sudo systemctl disable apache2

# OU altere as portas no arquivo .env antes de iniciar
nano .env  # Modificar HTTP_PORT=8081, etc.
```

## ⚡ Instalação e Uso Rápido

### 1. Clone o repositório
```bash
git clone https://github.com/leandrowferreira/docker-php-multiversion.git
cd docker-php-multiversion
```

### 2. Inicie o sistema
```bash
./scripts/start.sh
```

**🔧 Produção:** O sistema detecta automaticamente o ambiente e cria a estrutura em `/sistemas/`  
**🚀 Autostart:** Use `./scripts/start.sh --autostart` para configurar inicialização automática no boot  
**⚙️ Configuração:** Se não existir `.env`, será criado automaticamente a partir de `.env.example`

### 🔍 Como funciona a detecção automática de ambiente:

O sistema verifica dois arquivos para determinar o ambiente:

```bash
# DESENVOLVIMENTO é detectado quando:
# ✅ Existe o arquivo docker-compose.dev.yml
# ✅ Existe o diretório apps/

# PRODUÇÃO é detectado quando:
# ❌ NÃO existe docker-compose.dev.yml OU
# ❌ NÃO existe o diretório apps/
```

**📁 Estruturas por ambiente:**
- **Desenvolvimento**: Usa `./apps/`, `./mysql/data/`, `./redis/data/` (bind mounts)
- **Produção**: Cria `/sistemas/apps/`, `/sistemas/mysql/`, `/sistemas/redis/` (named volumes)

### 3. Crie sua primeira aplicação
```bash
# Sintaxe: ./scripts/app-create.sh <php-version> <app-name> <domain>
./scripts/app-create.sh php84 meuapp meuapp.local
```

### 4. Acesse sua aplicação
```bash
# Configure seu /etc/hosts (desenvolvimento)
echo "127.0.0.1 meuapp.local" | sudo tee -a /etc/hosts

# Acesse no navegador
curl -H "Host: meuapp.local" http://localhost
```

## 🚀 Criando uma Aplicação Laravel

Este guia mostra como criar uma aplicação Laravel completa após usar o `app-create.sh`:

### 1. Criar estrutura básica da aplicação
```bash
# Criar aplicação com PHP 8.4 (recomendado para Laravel)
./scripts/app-create.sh php84 meuapp-laravel meuapp.local

# Configurar /etc/hosts
echo "127.0.0.1 meuapp.local" | sudo tee -a /etc/hosts
```

### 2. Instalar Laravel no container
```bash
# ========================================
# OPÇÃO A: Instalação LOCAL (se tiver Composer/Laravel instalados localmente)
# ========================================

# Instalar Laravel localmente no diretório da aplicação
cd apps/php84/meuapp-laravel
rm public/index.php  # Remove o arquivo placeholder

# Com Laravel Installer local
laravel new . --force

# OU com Composer local
composer create-project laravel/laravel . --prefer-dist

# ========================================
# OPÇÃO B: Instalação NO CONTAINER (recomendado se não tiver ferramentas locais)
# ========================================

# Opção B1: Usando Laravel Installer no container
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/public/
rm index.php  # Remove o arquivo placeholder
cd ..
composer global require laravel/installer
laravel new . --force

# Opção B2: Usando Composer Create-Project no container
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/
rm -rf public/index.php  # Remove placeholder
composer create-project laravel/laravel . --prefer-dist
```

**💡 Qual opção escolher?**
- **Opção A (Local)**: Se você já tem Composer e/ou Laravel Installer instalados na sua máquina
- **Opção B (Container)**: Se você não tem as ferramentas instaladas localmente ou prefere manter tudo isolado no Docker

### 3. Configurar permissões
```bash
# ⚠️ APENAS NECESSÁRIO SE USOU INSTALAÇÃO NO CONTAINER (Opção B)
# Se instalou localmente (Opção A), pule este passo

# Entrar no container e ajustar permissões
docker compose exec app-php84 bash
chown -R www-data:www-data /var/www/html/meuapp-laravel/
chmod -R 755 /var/www/html/meuapp-laravel/
chmod -R 775 /var/www/html/meuapp-laravel/storage
chmod -R 775 /var/www/html/meuapp-laravel/bootstrap/cache
exit
```

**💡 Por que as permissões?**
- **Instalação local**: Arquivos já têm permissões corretas
- **Instalação no container**: Root cria arquivos, precisa ajustar para www-data

### 4. Configurar banco de dados
```bash
# Editar .env do Laravel
docker compose exec app-php84 nano /var/www/html/meuapp-laravel/.env
```

**Configurações do .env do Laravel:**
```bash
# Banco de dados MySQL 8.0 (recomendado)
DB_CONNECTION=mysql
DB_HOST=mysql8
DB_PORT=3306
DB_DATABASE=meuapp_laravel
DB_USERNAME=app_user
DB_PASSWORD=apppass123

# OU Banco MySQL 5.7 (para compatibilidade)
DB_CONNECTION=mysql
DB_HOST=mysql57
DB_PORT=3306
DB_DATABASE=meuapp_laravel
DB_USERNAME=app_user
DB_PASSWORD=apppass123

# Cache e Sessões com Redis
CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### 5. Criar banco de dados
```bash
# Conectar no MySQL e criar database
docker compose exec mysql8 mysql -u app_user -p
# Senha: apppass123

# Dentro do MySQL:
CREATE DATABASE meuapp_laravel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SHOW DATABASES;
EXIT;
```

### 6. Executar migrações
```bash
# Rodar migrações do Laravel
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/
php artisan migrate
exit
```

### 7. Configurar URL da aplicação
```bash
# Definir APP_URL no .env do Laravel
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/
php artisan config:cache
php artisan route:cache
exit
```

### 8. Testar a aplicação
```bash
# Acessar no navegador
curl -H "Host: meuapp.local" http://localhost

# Ou abrir no navegador: http://meuapp.local
```

### 🔧 Comandos úteis para Laravel

```bash
# Acessar container PHP para comandos Artisan
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/

# Comandos Laravel comuns
php artisan migrate               # Executar migrações
php artisan make:controller       # Criar controller
php artisan make:model           # Criar model
php artisan tinker               # Console interativo
php artisan serve               # NÃO usar (Nginx já serve)
php artisan config:clear        # Limpar cache de config
php artisan route:list          # Listar rotas

# Instalar dependências
composer install                 # Instalar dependências PHP
npm install && npm run dev       # Assets (se usar Node.js)
```

### 🗃️ Conectar no banco via PHPMyAdmin
```bash
# Acessar PHPMyAdmin
# URL: http://localhost:8080
# Servidor: mysql8 (ou mysql57)
# Usuário: app_user
# Senha: apppass123
# Database: meuapp_laravel
```

### ⚠️ Troubleshooting Laravel

**Problema: Erro de permissão**
```bash
docker compose exec app-php84 chown -R www-data:www-data /var/www/html/meuapp-laravel/
docker compose exec app-php84 chmod -R 775 /var/www/html/meuapp-laravel/storage
```

**Problema: APP_KEY não definida**
```bash
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/
php artisan key:generate
```

**Problema: Cache de configuração**
```bash
docker compose exec app-php84 bash
cd /var/www/html/meuapp-laravel/
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

## 📋 Comandos Disponíveis

### Gerenciamento do Sistema
```bash
# Iniciar todos os containers
./scripts/start.sh

# Parar todos os containers
./scripts/stop.sh

# Monitorar sistema em tempo real
./scripts/monitor.sh

# Testar configuração completa
./scripts/test-system.sh
```

### Gerenciamento de Aplicações
```bash
# Criar aplicação
./scripts/app-create.sh <php-version> <app-name> <domain> [options]

# Listar aplicações
./scripts/app-list.sh [--json] [--verbose] [--status-only]

# Remover aplicação
./scripts/app-remove.sh <php-version> <app-name>
```

### Gerenciamento SSL
```bash
# Gerar certificado SSL para aplicação
./scripts/ssl-create.sh <php-version> <app-name> [email]

# Renovar certificados SSL
./scripts/ssl-renew.sh [domain]
```

### Exemplos Práticos
```bash
# Laravel com PHP 8.4
./scripts/app-create.sh php84 blog blog.local

# Aplicação legada com PHP 5.6
./scripts/app-create.sh php56 old-system legacy.local

# Adicionar SSL a aplicação existente
./scripts/ssl-create.sh php84 blog admin@blog.local

# Renovar todos os certificados
./scripts/ssl-renew.sh

# Listagem com detalhes
./scripts/app-list.sh --verbose

# Status em JSON para integração
./scripts/app-list.sh --json
```

## 🏗️ Estrutura do Projeto

```
docker-php-multiversion/
├── 📁 apps/                    # Aplicações (desenvolvimento)
│   ├── php56/                  # Apps PHP 5.6
│   ├── php74/                  # Apps PHP 7.4
│   └── php84/                  # Apps PHP 8.4
├── 📁 docker/                  # Dockerfiles personalizados
│   ├── php56/                  # Configurações PHP 5.6
│   ├── php74/                  # Configurações PHP 7.4
│   ├── php81/                  # Configurações PHP 8.1 (futuro)
│   └── php84/                  # Configurações PHP 8.4
├── 📁 logs/                    # Logs dos serviços
│   ├── mysql/                  # Logs MySQL
│   ├── nginx/                  # Logs Nginx
│   ├── php56/                  # Logs PHP 5.6
│   ├── php74/                  # Logs PHP 7.4
│   └── php84/                  # Logs PHP 8.4
├── 📁 mysql/                   # Configurações MySQL
│   ├── data/                   # Dados dos bancos (desenvolvimento)
│   │   ├── mysql57/            # Dados MySQL 5.7
│   │   └── mysql8/             # Dados MySQL 8.0
│   └── init/                   # Scripts de inicialização
│       └── 01-init.sql         # Configuração inicial MySQL 8.0
├── 📁 nginx/                   # Configurações Nginx
│   ├── conf.d/                 # Configurações de sites
│   ├── ssl/                    # Certificados SSL
│   └── templates/              # Templates automáticos
├── 📁 prompts/                 # Documentação do desenvolvimento
├── 📁 redis/                   # Configurações Redis
│   └── data/                   # Dados Redis (desenvolvimento)
├── 📁 scripts/                 # Scripts de automação
│   ├── start.sh               # 🚀 Iniciar sistema
│   ├── stop.sh                # 🛑 Parar sistema
│   ├── app-create.sh          # ➕ Criar aplicação
│   ├── app-list.sh            # 📋 Listar aplicações
│   ├── app-remove.sh          # ➖ Remover aplicação
│   ├── monitor.sh             # 📊 Monitoramento
│   └── test-system.sh         # 🧪 Testes do sistema
├── .env.example               # 🔧 Configurações de exemplo
├── .gitignore                 # 🚫 Arquivos ignorados
├── docker-compose.yml         # 🐳 Configuração principal
├── docker-compose.dev.yml     # 🔧 Overrides desenvolvimento
├── LICENSE                    # ⚖️ Licença MIT
└── 📄 README.md               # 📖 Documentação
```

## 🌍 Ambientes

### Detecção Automática
O sistema analisa dois fatores para determinar o ambiente:

```bash
# Script de detecção (simplificado):
if [ -f "docker-compose.dev.yml" ] && [ -d "apps" ]; then
    AMBIENTE="desenvolvimento" 
else
    AMBIENTE="producao"
fi
```

### Desenvolvimento
- **Critério de detecção**: Existe `docker-compose.dev.yml` **E** existe diretório `apps/`
- **Volumes**: Bind mounts para edição ao vivo
- **Diretório apps**: `./apps/` (local)
- **Dados MySQL**: `./mysql/data/` (local)
- **Dados Redis**: `./redis/data/` (local)
- **Benefícios**: Hot reload, debug facilitado, edição direta

### Produção
- **Critério de detecção**: **NÃO** existe `docker-compose.dev.yml` **OU** **NÃO** existe diretório `apps/`
- **Volumes**: Named volumes para performance
- **Diretório apps**: `/sistemas/apps/` (sistema)
- **Dados MySQL**: `/sistemas/mysql/` (sistema)
- **Dados Redis**: `/sistemas/redis/` (sistema)
- **Autostart**: Docker configurado para iniciar automaticamente no boot
- **Benefícios**: Performance otimizada, isolamento, alta disponibilidade

### 🔄 Autostart em Produção
Para configurar o sistema para iniciar automaticamente no boot:
```bash
# Configurar autostart do Docker e containers
./scripts/start.sh --autostart

# Opções do start.sh:
./scripts/start.sh              # Configurar estrutura e iniciar containers
./scripts/start.sh --setup      # Apenas configurar estrutura 
./scripts/start.sh --autostart  # Configurar auto-start do sistema (systemd)
```

**O que o `--autostart` configura:**
- Docker service habilitado (`systemctl enable docker`)
- Containers com restart policy "unless-stopped"
- Estrutura de diretórios em `/sistemas/` (produção)

## ⚙️ Configuração

### Variáveis de Ambiente (.env)
O projeto usa um arquivo `.env` para configurações flexíveis:

```bash
# O arquivo .env é criado automaticamente na primeira execução
./scripts/start.sh  # Copia .env.example para .env se não existir

# Para personalizar, edite o arquivo .env
nano .env
```

### 🔄 Aplicando Alterações no .env
Após alterar o arquivo `.env`, é necessário reiniciar os containers para aplicar as mudanças:

```bash
# Método 1: Parar e iniciar (recomendado)
./scripts/stop.sh
./scripts/start.sh

# Método 2: Reiniciar containers específicos
docker compose restart

# Método 3: Recriar containers (para mudanças estruturais)
docker compose down
docker compose up -d
```

**⚠️ Importante:**
- **Portas**: Mudanças de portas requerem reinicialização completa
- **Credenciais MySQL**: Mudanças só se aplicam a novos bancos/usuários
- **Performance**: Configurações de memória requerem restart dos containers MySQL

### Principais Configurações
```bash
# Bancos de Dados (credenciais para MySQL 8.0)
MYSQL8_ROOT_PASSWORD=rootpass123
MYSQL8_USER=app_user
MYSQL8_PASSWORD=apppass123

# Bancos de Dados (credenciais para MySQL 5.7)
MYSQL57_ROOT_PASSWORD=rootpass123
MYSQL57_USER=app_user
MYSQL57_PASSWORD=apppass123

# Portas (altere se houver conflitos)
HTTP_PORT=80
HTTPS_PORT=443
MYSQL8_PORT=3306
MYSQL57_PORT=3307
REDIS_PORT=6379
PHPMYADMIN_PORT=8080

# Performance
MYSQL_INNODB_BUFFER_POOL_SIZE=134217728  # 128MB
```

**⚠️ Lembre-se:** Após alterar qualquer configuração no `.env`, execute `./scripts/stop.sh` e `./scripts/start.sh` para aplicar as mudanças.

## 📊 Monitoramento e Logs

```bash
# Status detalhado do sistema
./scripts/app-list.sh --verbose

# Logs em tempo real
docker compose logs -f

# Logs específicos de um container
docker compose logs -f app-php84

# Verificar tentativas de acesso a domínios não configurados
docker compose logs nginx | grep "undefined_domains"

# Monitoramento interativo
./scripts/monitor.sh
```

## 🔒 SSL e Segurança

### Comportamento de Domínios
- **Domínios configurados**: Retornam conteúdo das aplicações (Status 200)
- **Domínios não configurados**: Retornam 404 automaticamente
- **Proteção**: Evita vazamento de conteúdo entre aplicações

### 🔐 Geração de Certificados SSL Automática

O sistema inclui geração automática de certificados SSL/TLS usando **Let's Encrypt**, com suporte completo para produção.

#### **Script de Geração SSL**
```bash
# Sintaxe básica
./scripts/ssl-create.sh <php_version> <app_name> [email]

# Exemplos práticos
./scripts/ssl-create.sh php84 loja admin@empresa.com
./scripts/ssl-create.sh php74 blog
./scripts/ssl-create.sh php56 legado suporte@site.com
```

#### **Pré-requisitos para SSL**
- ✅ Domínio apontando para o servidor (DNS configurado)
- ✅ Aplicação funcionando via HTTP primeiro
- ✅ Portas 80 e 443 abertas no firewall/security groups
- ✅ Sistema em produção (certificados reais só funcionam em produção)

#### **O que o script SSL faz automaticamente:**
1. 🔍 **Valida** se a aplicação existe e está acessível
2. 🐳 **Inicia** container Certbot se necessário
3. 📁 **Cria** estrutura de diretórios SSL com permissões corretas
4. ⚙️ **Configura** Nginx para validação ACME challenge
5. 🔐 **Gera** certificado Let's Encrypt (válido por 90 dias)
6. 📋 **Atualiza** configuração Nginx para HTTPS usando templates
7. 🔄 **Aplica** redirecionamento HTTP → HTTPS automático
8. 🧪 **Testa** se HTTPS está funcionando corretamente

#### **Templates HTTPS Automáticos**
Cada versão PHP tem seu template HTTPS otimizado:
- `nginx/templates/php84-https-template.conf` - PHP 8.4 + TLS 1.3
- `nginx/templates/php74-https-template.conf` - PHP 7.4 + Headers seguros
- `nginx/templates/php56-https-template.conf` - PHP 5.6 + Compatibilidade legada

### 🔄 Renovação Automática de Certificados

#### **Script de Renovação**
```bash
# Renovar todos os certificados
./scripts/ssl-renew.sh

# Renovar certificado específico
./scripts/ssl-renew.sh webhook-store.com
```

#### **Configuração de Cron para Renovação Automática**
```bash
# Editar crontab
crontab -e

# Adicionar linha para renovação automática (verifica diariamente às 12h)
0 12 * * * /caminho/para/docker-php-multiversion/scripts/ssl-renew.sh >> /var/log/ssl-renewal.log 2>&1
```

### 📋 Arquitetura SSL do Sistema

#### **Containers e Volumes**
```yaml
# Container Certbot para Let's Encrypt
certbot:
  image: certbot/certbot
  volumes:
    - ./nginx/ssl/letsencrypt:/etc/letsencrypt
    - ./nginx/ssl/lib:/var/lib/letsencrypt  
    - ./nginx/ssl/www:/var/www/certbot

# Nginx com volumes SSL
nginx:
  volumes:
    - ./nginx/ssl/letsencrypt:/etc/letsencrypt
    - ./nginx/ssl/www:/var/www/certbot
```

#### **Estrutura de Diretórios SSL**
```
nginx/ssl/
├── letsencrypt/          # Certificados Let's Encrypt
│   └── live/            
│       └── domain.com/   # Certificados específicos do domínio
│           ├── fullchain.pem
│           └── privkey.pem
├── lib/                  # Dados do Certbot
├── www/                  # Webroot para ACME challenge
└── cert.pem             # Certificados desenvolvimento (auto-assinados)
    key.pem
```

### 🛡️ Configurações de Segurança SSL

#### **Protocolos e Ciphers**
- **TLS 1.2 e 1.3**: Protocolos modernos e seguros
- **Perfect Forward Secrecy**: Ciphers ECDHE preferenciais
- **HSTS**: Strict Transport Security habilitado
- **Security Headers**: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection

#### **Exemplo de Configuração Gerada**
```nginx
# Configuração HTTPS automática gerada pelo script
server {
    listen 443 ssl http2;
    server_name meusite.com;
    
    # Certificados Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/meusite.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meusite.com/privkey.pem;
    
    # Protocolos e segurança
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    
    # ACME Challenge para renovação
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

# Redirecionamento HTTP → HTTPS
server {
    listen 80;
    server_name meusite.com;
    return 301 https://$server_name$request_uri;
}
```

### 🚨 Troubleshooting SSL

#### **Problemas Comuns e Soluções**

1. **"Permission denied" nos diretórios SSL**
   ```bash
   sudo chown -R $(whoami):$(id -gn) nginx/ssl/
   ```

2. **"Domain not accessible via HTTP"**
   - Verificar se DNS aponta para o servidor
   - Confirmar que aplicação está rodando (HTTP primeiro)
   - Verificar firewall/security groups (portas 80/443)

3. **"Certbot container not running"**
   ```bash
   docker compose up -d certbot
   docker compose logs certbot
   ```

4. **"Template HTTPS not found"**
   - Verificar se versão PHP é suportada (php84, php74, php56)
   - Confirmar que templates existem em `nginx/templates/`

5. **Certificado não renova automaticamente**
   ```bash
   # Testar renovação manual
   ./scripts/ssl-renew.sh
   
   # Verificar logs
   docker compose logs certbot
   ```

### ⚡ Configuração SSL Rápida

#### **Cenário 1: Nova aplicação com SSL**
```bash
# 1. Criar aplicação
./scripts/app-create.sh php84 loja meusite.com

# 2. Aguardar DNS propagar e aplicação estar acessível
curl http://meusite.com  # Deve retornar 200

# 3. Gerar SSL
./scripts/ssl-create.sh php84 loja admin@meusite.com
```

#### **Cenário 2: Adicionar SSL a aplicação existente**
```bash
# SSL em aplicação já funcionando
./scripts/ssl-create.sh php74 blog-existente contato@blog.com
```

### 🔒 Configuração SSL Automática
```bash
# Adicionar SSL a uma aplicação existente
./scripts/ssl-create.sh php84 meuapp admin@meuapp.com

# Criar aplicação já com SSL (primeiro HTTP, depois SSL)
./scripts/app-create.sh php84 secure secure.com
# Aguardar aplicação estar acessível via HTTP
./scripts/ssl-create.sh php84 secure admin@secure.com
```

### 📊 Status e Monitoramento SSL
```bash
# Verificar certificados instalados
docker compose exec certbot certbot certificates

# Verificar validade de certificado específico
openssl s_client -connect meusite.com:443 -servername meusite.com | openssl x509 -noout -dates

# Logs do processo SSL
docker compose logs certbot
docker compose logs nginx | grep ssl
```

## 🎯 Exemplos Práticos

### 1. **Migração Gradual de Sistema Legacy**
```bash
# Manter sistema antigo funcionando
./scripts/app-create.sh php56 erp-legado erp.empresa.com

# Desenvolver nova versão em paralelo
./scripts/app-create.sh php84 erp-novo beta.empresa.com

# Ambos sistemas rodando simultaneamente para testes A/B
```

### 2. **Prototipação Rápida para Clientes**
```bash
# Cliente A - E-commerce em Laravel
./scripts/app-create.sh php84 loja-cliente-a loja-a.demo.com --ssl

# Cliente B - Sistema legado CakePHP
./scripts/app-create.sh php74 sistema-cliente-b app-b.demo.com --ssl

# Cliente C - WordPress customizado
./scripts/app-create.sh php81 site-cliente-c site-c.demo.com
```

### 3. **Ambiente de Desenvolvimento Multi-Projeto**
```bash
# Cada desenvolvedor com seus projetos isolados
./scripts/app-create.sh php84 projeto-novo dev.local
./scripts/app-create.sh php74 manutencao-sistema legacy.local
./scripts/app-create.sh php56 sistema-muito-antigo old.local

# Todos rodando simultaneamente na mesma máquina
```

## 📈 Performance

- **Containers otimizados**: Imagens Alpine para menor footprint
- **PHP-FPM**: Pool workers configurados por uso
- **Nginx**: Compressão e cache configurados
- **MySQL**: InnoDB otimizado para cada versão
- **Redis**: Persistência configurável

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'feat: adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📝 Changelog

Ver [Releases](https://github.com/leandrowferreira/docker-php-multiversion/releases) para histórico de versões.

## 🆘 Suporte

- **Issues**: [GitHub Issues](https://github.com/leandrowferreira/docker-php-multiversion/issues)
- **Documentação**: Este README e comentários nos scripts
- **Wiki**: [Project Wiki](https://github.com/leandrowferreira/docker-php-multiversion/wiki)

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- Comunidade Docker pela excelente documentação
- Projetos Laravel e PHP pela inspiração
- Contribuidores e usuários que reportam issues e melhorias

---

<div align="center">

**⭐ Se este projeto foi útil, considere dar uma estrela!**

[![GitHub stars](https://img.shields.io/github/stars/leandrowferreira/docker-php-multiversion.svg?style=social&label=Star)](https://github.com/leandrowferreira/docker-php-multiversion)

</div>
