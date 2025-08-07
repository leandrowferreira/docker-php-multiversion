# Sistema de Containers para Aplicações Laravel

Este projeto configura um ambiente Docker completo para hospedar múltiplas aplicações Laravel com diferentes versões do PHP, bancos de dados MySQL e proxy reverso Nginx.

## 🏗️ Arquitetura

- **Nginx**: Proxy reverso com SSL/HTTPS
- **PHP-FPM**: Containers separados para PHP 8.1, 7.4 e 5.6
- **MySQL**: MySQL 8.0 (principal) e MySQL 5.7 (legado)
- **Redis**: Cache e sessões
- **Volumes persistentes**: Dados armazenados em `/sistemas`

## 📋 Pré-requisitos

- EC2 com Debian/Ubuntu
- Docker e Docker Compose instalados
- Mínimo 2GB RAM (t3a.small)
- Acesso root/sudo

## 🚀 Instalação

### 1. Preparar o ambiente

```bash
# Clonar ou copiar os arquivos para o servidor
cd /home/usuario/sistemas-docker

# Tornar scripts executáveis
chmod +x scripts/*.sh

# Preparar estrutura de diretórios
./scripts/setup-directories.sh
```

### 2. Configurar variáveis de ambiente

```bash
# Copiar e ajustar configurações
cp .env.example .env
nano .env  # Ajustar senhas e configurações
```

### 3. Gerar certificados SSL

```bash
# Para desenvolvimento (certificado auto-assinado)
./scripts/generate-ssl.sh

# Para produção, copie seus certificados válidos para nginx/ssl/
```

### 4. Iniciar o sistema

```bash
# Primeiro build e start
docker-compose up -d --build

# Verificar status
docker-compose ps
```

### 5. Configurar auto-start

```bash
# Configurar para iniciar automaticamente com a máquina
./scripts/setup-autostart.sh
```

## 📁 Estrutura de Diretórios

```
/sistemas/
├── apps/
│   ├── php81/          # Aplicações PHP 8.1
│   ├── php74/          # Aplicações PHP 7.4
│   └── php56/          # Aplicações PHP 5.6
├── mysql8/
│   ├── data/           # Dados MySQL 8.0
│   └── conf/           # Configurações MySQL 8.0
├── mysql57/
│   ├── data/           # Dados MySQL 5.7
│   └── conf/           # Configurações MySQL 5.7
├── redis/
│   └── data/           # Dados Redis
└── backups/            # Backups dos bancos
```

## 🔧 Gerenciamento

### Adicionar nova aplicação

```bash
# Sintaxe: ./add-app.sh <nome> <versao-php> <dominio>
./scripts/add-app.sh minha-loja php81 loja.exemplo.com

# Colocar código da aplicação em:
# /sistemas/apps/php81/minha-loja/
```

### Monitoramento

```bash
# Ver status e recursos
./scripts/monitor.sh

# Logs específicos
docker-compose logs nginx
docker-compose logs mysql8
docker-compose logs app-php81
```

### Backup

```bash
# Backup de todos os bancos
./scripts/backup-db.sh

# Backup específico
./scripts/backup-db.sh mysql8
./scripts/backup-db.sh mysql57
```

## 🌐 Configuração de Domínios

### Exemplo de configuração DNS

Para cada aplicação, configure o DNS para apontar para o IP da EC2:

```
app81.exemplo.com    A    SEU-IP-EC2
app74.exemplo.com    A    SEU-IP-EC2
app56.exemplo.com    A    SEU-IP-EC2
```

### Configuração Nginx

Cada aplicação tem sua própria configuração em `nginx/conf.d/app-*.conf`. O script `add-app.sh` cria automaticamente essas configurações.

## 🔌 Portas e Serviços

| Serviço | Container | Porta Host | Porta Container |
|---------|-----------|------------|-----------------|
| Nginx | nginx-proxy | 80, 443 | 80, 443 |
| MySQL 8.0 | mysql8 | 3306 | 3306 |
| MySQL 5.7 | mysql57 | 3307 | 3306 |
| Redis | redis-cache | 6379 | 6379 |
| PHP 8.1 | laravel-php81 | - | 9000 |
| PHP 7.4 | laravel-php74 | - | 9000 |
| PHP 5.6 | laravel-php56 | - | 9000 |

## 🔒 Segurança

- Certificados SSL configurados
- Headers de segurança no Nginx
- Rate limiting habilitado
- Acesso negado a arquivos sensíveis
- Containers em rede isolada

## 📊 Performance

### Configurações otimizadas para t3a.small (2GB RAM):

- **MySQL**: Buffer pool 128MB, max 50 conexões
- **PHP-FPM**: Pool dinâmico com até 20 processos
- **Nginx**: Gzip habilitado, cache de arquivos estáticos
- **OPCache**: Habilitado em todos os containers PHP

## 🚨 Troubleshooting

### Container não inicia
```bash
# Ver logs detalhados
docker-compose logs nome-do-servico

# Reconstruir container
docker-compose up -d --build nome-do-servico
```

### Problemas de permissão
```bash
# Ajustar permissões dos volumes
sudo chown -R $USER:$USER /sistemas
```

### Erro de memória
```bash
# Verificar uso de recursos
./scripts/monitor.sh

# Ajustar configurações no docker-compose.yml
```

### SSL/HTTPS não funciona
```bash
# Verificar certificados
ls -la nginx/ssl/

# Recriar certificados
./scripts/generate-ssl.sh
```

## 🔄 Comandos Úteis

```bash
# Parar todos os containers
docker-compose down

# Reiniciar um serviço específico
docker-compose restart nginx

# Entrar em um container
docker exec -it laravel-php81 bash

# Ver logs em tempo real
docker-compose logs -f nginx

# Atualizar apenas um serviço
docker-compose up -d nginx

# Limpar recursos não utilizados
docker system prune -f
```

## 📈 Escalabilidade

### Adicionar nova versão do PHP

1. Criar diretório `docker/phpXX/`
2. Copiar e adaptar Dockerfile
3. Adicionar serviço no `docker-compose.yml`
4. Criar configuração Nginx

### Adicionar novo banco de dados

1. Adicionar serviço MySQL no `docker-compose.yml`
2. Configurar porta diferente
3. Criar volume para dados
4. Ajustar scripts de backup

### Load Balancer

Para aplicações com alto tráfego, considere:
- AWS Application Load Balancer
- Múltiplas instâncias da aplicação
- Auto Scaling Groups

## 🔧 Manutenção

### Atualizações
```bash
# Atualizar imagens
docker-compose pull

# Reconstruir containers
docker-compose up -d --build
```

### Limpeza
```bash
# Limpar logs antigos
sudo find /sistemas/*/logs -name "*.log" -mtime +30 -delete

# Limpar backups antigos (feito automaticamente)
```

## 📞 Suporte

Para dúvidas sobre configuração específica ou problemas, verifique:

1. Logs dos containers: `docker-compose logs`
2. Status dos serviços: `./scripts/monitor.sh`
3. Configurações Nginx: `nginx/conf.d/`
4. Variáveis de ambiente: `.env`

---

**Projeto**: Sistema de Containers Laravel Multi-PHP  
**Versão**: 1.0  
**Compatibilidade**: Debian/Ubuntu, Docker 20+, Docker Compose 2+
