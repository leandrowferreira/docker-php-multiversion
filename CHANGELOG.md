# Changelog - Sistema de Containers Laravel Multi-PHP

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado no [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.4.0] - 2025-08-07

### Adicionado
- 🏗️ Sistema completo de templates Nginx organizados
- 📁 Separação clara entre templates HTTP e HTTPS
- 🔧 Scripts de automação aprimorados:
  - `add-app.sh`: Criação automática com detecção de template
  - `remove-app.sh`: Remoção segura (preserva dados por padrão)
  - `setup-ssl.sh`: Placeholder para configuração SSL futura
- 📚 Documentação completa nos templates (`nginx/templates/README.md`)
- 🛡️ Headers de segurança otimizados por versão PHP
- 🎯 Workflow HTTP-first com SSL opcional

### Melhorado
- 📝 Nomenclatura padronizada dos templates:
  - `php{56,74,84}-http-template.conf` (HTTP apenas)
  - `php{56,74,84}-https-template.conf` (HTTPS com SSL)
- 🔄 Comportamento padrão alterado para HTTP-only
- 📦 Paths corrigidos para compatibilidade com volumes Docker
- 🧹 .gitignore reorganizado sem duplicatas
- ⚡ Performance otimizada por versão PHP (timeouts, buffers)

### Corrigido
- 🐛 Mapeamento correto de volumes Docker nos templates
- 🔗 FastCGI pass para containers corretos
- 🗂️ Estrutura de diretórios consistente

## [1.3.0] - 2025-08-07

### Adicionado
- **Ambiente de testes local completo** com múltiplas versões PHP/MySQL
- **Hosts de desenvolvimento**:
  - `teste1.docker.local` - PHP 5.6 + MySQL 5.7 
  - `teste2.docker.local` - PHP 7.4 + MySQL 8.0
- **Configuração Nginx para testes locais** (`nginx/conf.d/testes-locais.conf`)
- **Container PHP 5.6 refatorado** com Ubuntu 22.04 + PPA Ondrej
- **Configuração TCP automática** para PHP-FPM 5.6 (porta 9000)
- **Arquivos de exemplo funcionais** (`examples/Dockerfile 5.6`)
- **Pool FPM configurado** (`docker/php56/fmp-pool.conf`)

### Corrigido
- **Container PHP 5.6**: Migração de Debian Stretch EOL para Ubuntu 22.04
- **PHP-FPM 5.6**: Configuração automática de socket Unix para TCP
- **Dependências Docker Compose**: `app-php81` → `app-php84` corrigida
- **Repositórios PHP 5.6**: PPA Ondrej estável em Ubuntu 22.04
- **Conectividade**: PHP 5.6 ↔ MySQL 5.7 validada e funcional

### Melhorado
- **Estabilidade do PHP 5.6**: Base Ubuntu sólida em vez de Debian EOL
- **Scripts de automação**: Permissões de execução corrigidas
- **Documentação técnica**: Exemplos de configuração funcional
- **Ambiente de desenvolvimento**: Setup local padronizado e reproduzível
- **Conectividade entre containers**: Validação completa de todos os serviços

### Testado e Validado
- ✅ **PHP 5.6** com MySQL 5.7 - Conectividade completa
- ✅ **PHP 7.4** com MySQL 8.0 - Funcionamento perfeito  
- ✅ **PHP 8.4** mantido da v1.2.0 - Estável
- ✅ **PHPMyAdmin** - Acesso aos dois bancos MySQL
- ✅ **Hosts locais** - Resolução DNS e configuração Nginx
- ✅ **Logs organizados** - Por versão PHP e serviço

### Ambiente de Desenvolvimento
Esta versão estabelece um **ambiente de desenvolvimento local robusto** que permite:
- Testar migrações PHP antes do deploy em produção
- Validar compatibilidade entre diferentes versões PHP/MySQL
- Desenvolvimento simultâneo com múltiplas versões
- Replicação fácil do ambiente pela equipe

### Arquivos Técnicos
- `docker/php56/Dockerfile` - Refatoração completa Ubuntu + Ondrej
- `docker/php56/entrypoint.sh` - Configuração automática TCP FPM
- `nginx/conf.d/testes-locais.conf` - Hosts de desenvolvimento
- `examples/Dockerfile 5.6` - Referência técnica funcional

## [1.2.0] - 2025-08-07

### Adicionado
- **PHP 8.4** como nova versão principal (mais recente disponível)
- **Sistema de documentação de prompts** em formato Markdown
- **Registro histórico completo** de desenvolvimento no diretório `/prompts`
- **Links funcionais** na documentação para navegação

### Alterado
- **BREAKING**: PHP 8.1 removido, substituído por PHP 8.4
- **Versões PHP suportadas**: 8.4, 7.4, 5.6 (em vez de 8.1, 7.4, 5.6)
- **Estrutura Docker**: `docker/php81/` → `docker/php84/`
- **Container**: `laravel-php81` → `laravel-php84`
- **Volumes**: `/sistemas/apps/php81/` → `/sistemas/apps/php84/`
- **Configuração Nginx**: `app-php81.conf` → `app-php84.conf`
- **Comandos Makefile**: `logs-php81` → `logs-php84`, `shell-php81` → `shell-php84`
- **Documentação**: Convertida para Markdown com links clicáveis
- **Scripts**: Validação e exemplos atualizados para PHP 8.4

### Removido
- **PHP 8.1**: Container, configurações e referências
- **Comando automático de prompts** do Makefile (simplificação)

### Melhorado
- **Performance**: PHP 8.4 oferece melhorias significativas
- **Compatibilidade**: Mantido suporte para aplicações legadas (5.6, 7.4)
- **Documentação**: Formato Markdown para melhor renderização
- **Organização**: Sistema estruturado de registro de desenvolvimento

### Migração
Para migrar aplicações existentes:
1. Reconstruir container: `docker-compose build app-php84`
2. Mover aplicações: `/sistemas/apps/php81/` → `/sistemas/apps/php84/`
3. Testar compatibilidade com PHP 8.4
4. Atualizar configurações se necessário

## [1.0.0] - 2025-08-07

### Adicionado
- **Sistema completo de containerização** para aplicações Laravel
- **Múltiplas versões PHP**: Suporte para PHP 8.1, 7.4 e 5.6 simultaneamente
- **Proxy reverso Nginx** com SSL/HTTPS configurado
- **Bancos de dados**: MySQL 8.0 (principal) e MySQL 5.7 (legado)
- **Cache Redis** para sessões e cache de aplicações
- **Volumes persistentes** em `/sistemas` para dados do host
- **Auto-start** do sistema na inicialização da EC2
- **Scripts de gerenciamento**:
  - `setup-directories.sh` - Preparação do ambiente
  - `add-app.sh` - Adicionar novas aplicações
  - `generate-ssl.sh` - Gerar certificados SSL
  - `backup-db.sh` - Backup automático dos bancos
  - `monitor.sh` - Monitoramento do sistema
  - `setup-autostart.sh` - Configurar auto-start
  - `test-system.sh` - Testes de funcionamento
- **Makefile** com comandos simplificados
- **Docker Compose** para desenvolvimento e produção
- **Configurações otimizadas** para EC2 t3a.small (2GB RAM)
- **Documentação completa**:
  - README.md - Documentação principal
  - QUICKSTART.md - Guia de início rápido
  - examples/laravel-config.md - Exemplos de configuração
- **Configurações de segurança**:
  - Headers de segurança no Nginx
  - Rate limiting
  - Acesso negado a arquivos sensíveis
  - Rede Docker isolada

### Características Técnicas
- **Arquitetura modular** para fácil escalabilidade
- **Zero downtime** para adição de novas aplicações
- **Performance otimizada** para recursos limitados
- **Backup automático** com retenção configurável
- **Logs centralizados** e estruturados
- **Certificados SSL** auto-assinados incluídos
- **Configuração via .env** para fácil manutenção

### Estrutura do Projeto
```
├── docker-compose.yml          # Configuração principal
├── docker-compose.dev.yml      # Override para desenvolvimento
├── .env.example               # Modelo de configuração
├── Makefile                   # Comandos simplificados
├── README.md                  # Documentação principal
├── QUICKSTART.md              # Guia rápido
├── docker/                    # Dockerfiles customizados
│   ├── php81/
│   ├── php74/
│   └── php56/
├── nginx/                     # Configurações Nginx
│   ├── nginx.conf
│   └── conf.d/
├── scripts/                   # Scripts de gerenciamento
└── examples/                  # Exemplos e documentação adicional
```

### Requisitos do Sistema
- **EC2**: Mínimo t3a.small (2GB RAM, 2 vCPUs)
- **OS**: Debian/Ubuntu
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Acesso**: Root/sudo necessário para setup inicial

### Casos de Uso Suportados
- ✅ Múltiplas aplicações Laravel com versões PHP diferentes
- ✅ Sistemas legados (PHP 5.6) e modernos (PHP 8.1)
- ✅ Bancos de dados compartilhados ou dedicados
- ✅ Aplicações com diferentes níveis de tráfego
- ✅ Desenvolvimento local e produção
- ✅ Backup e restore de dados
- ✅ Monitoramento e logs

### Histórico de Versões
- **v1.3.0**: Ambiente de testes local + PHP 5.6 refatorado
- **v1.2.0**: Migração para PHP 8.4 + Sistema de documentação
- **v1.1.0**: Let's Encrypt automático + Melhorias de routing
- **v1.0.0**: Sistema completo inicial

### Próximas Versões Planejadas
- **v1.4.0**: Dashboard de monitoramento web
- **v1.5.0**: Suporte a PostgreSQL
- **v2.0.0**: Kubernetes migration path
