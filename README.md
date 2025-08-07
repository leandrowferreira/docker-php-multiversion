# Docker PHP Multiversion

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg?logo=docker)](https://www.docker.com/)
[![PHP](https://img.shields.io/badge/PHP-5.6%20|%207.4%20|%208.4-777BB4.svg?logo=php)](https://www.php.net/)
[![Nginx](https://img.shields.io/badge/Nginx-1.25+-green.svg?logo=nginx)](https://nginx.org/)
[![MySQL](https://img.shields.io/badge/MySQL-5.7%20|%208.0-4479A1.svg?logo=mysql)](https://www.mysql.com/)
[![Redis](https://img.shields.io/badge/Redis-7.0+-DC382D.svg?logo=redis)](https://redis.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/leandrowferreira/docker-php-multiversion/graphs/commit-activity)

Sistema Docker completo para desenvolvimento e produção com suporte simultâneo a múltiplas versões PHP, automação de deploy e gerenciamento unificado de aplicações.

## 🚀 Características Principais

- **🐘 Múltiplas versões PHP**: Suporte simultâneo a PHP 5.6, 7.4 e 8.4
- **⚡ Deploy automatizado**: Criação de aplicações com um comando
- **🔄 Detecção de ambiente**: Automática entre desenvolvimento e produção
- **🎯 Framework agnóstico**: Suporte a Laravel, CakePHP e qualquer framework PHP
- **📦 Stack completa**: Nginx, MySQL (5.7/8.0), Redis e PHPMyAdmin inclusos
- **🔒 SSL automático**: Configuração Let's Encrypt integrada
- **📊 Monitoramento**: Scripts de status e logs em tempo real
- **🛠️ Zero configuração**: Funciona out-of-the-box

## 🛠️ Stack Tecnológica

| Componente | Versão | Portas | Descrição |
|------------|--------|--------|-----------|
| **Nginx** | Alpine | 80, 443 | Proxy reverso e servidor web |
| **PHP-FPM** | 5.6, 7.4, 8.4 | 9000 | Processamento PHP simultâneo |
| **MySQL** | 5.7, 8.0 | 3306, 3307 | Bancos de dados |
| **Redis** | 7-Alpine | 6379 | Cache e sessões |
| **PHPMyAdmin** | Latest | 8080 | Administração MySQL |

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

### Exemplos Práticos
```bash
# Laravel com PHP 8.4
./scripts/app-create.sh php84 blog blog.local

# Aplicação legada com PHP 5.6
./scripts/app-create.sh php56 old-system legacy.local

# API com PHP 7.4 e SSL
./scripts/app-create.sh php74 api api.local --ssl

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
│   ├── php56/ php74/ php84/    # Configurações por versão
├── 📁 nginx/                   # Configurações Nginx
│   ├── conf.d/                 # Configurações de sites
│   ├── templates/              # Templates automáticos
│   └── ssl/                    # Certificados SSL
├── 📁 scripts/                 # Scripts de automação
│   ├── start.sh               # 🚀 Iniciar sistema
│   ├── stop.sh                # 🛑 Parar sistema
│   ├── app-create.sh          # ➕ Criar aplicação
│   ├── app-list.sh            # 📋 Listar aplicações
│   ├── app-remove.sh          # ➖ Remover aplicação
│   ├── monitor.sh             # 📊 Monitoramento
│   └── test-system.sh         # 🧪 Testes do sistema
├── docker-compose.yml         # 🐳 Configuração principal
├── docker-compose.dev.yml     # 🔧 Overrides desenvolvimento
└── 📄 README.md
```

## 🌍 Ambientes

### Desenvolvimento
- **Detecção**: Presença do arquivo `docker-compose.dev.yml`
- **Volumes**: Bind mounts para edição ao vivo
- **Diretório**: `./apps/`
- **Benefícios**: Hot reload, debug facilitado

### Produção
- **Detecção**: Ausência do arquivo `docker-compose.dev.yml`
- **Volumes**: Named volumes para performance
- **Diretório**: `/sistemas/apps/`
- **Benefícios**: Performance otimizada, isolamento

## 📊 Monitoramento e Logs

```bash
# Status detalhado do sistema
./scripts/app-list.sh --verbose

# Logs em tempo real
docker compose logs -f

# Logs específicos de um container
docker compose logs -f app-php84

# Monitoramento interativo
./scripts/monitor.sh
```

## 🔒 SSL e Segurança

### Configuração SSL Automática
```bash
# Adicionar SSL a uma aplicação existente
./scripts/setup-ssl.sh meuapp meuapp.com

# Criar aplicação já com SSL
./scripts/app-create.sh php84 secure secure.com --ssl
```

### Certificados Let's Encrypt
- Renovação automática configurada
- Suporte a múltiplos domínios
- Redirecionamento HTTP → HTTPS automático

## 🎯 Casos de Uso

### 1. **Migração Gradual PHP**
```bash
# Manter sistema legado em PHP 5.6
./scripts/app-create.sh php56 legacy-system old.company.com

# Nova funcionalidade em PHP 8.4
./scripts/app-create.sh php84 new-feature app.company.com
```

### 2. **Ambiente de Desenvolvimento Multi-projeto**
```bash
# Cada projeto em sua versão ideal
./scripts/app-create.sh php74 projeto-cliente1 client1.local
./scripts/app-create.sh php84 projeto-cliente2 client2.local
./scripts/app-create.sh php56 projeto-legado legacy.local
```

### 3. **Deploy em Produção**
```bash
# Remover docker-compose.dev.yml para produção
mv docker-compose.dev.yml docker-compose.dev.yml.backup

# Sistema detecta automaticamente o ambiente
./scripts/start.sh
./scripts/app-create.sh php84 production app.domain.com --ssl
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
