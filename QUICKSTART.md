# 🚀 Quick Start - Sistema de Containers Laravel

## Instalação Rápida (5 minutos)

### 1. Preparar ambiente
```bash
# Fazer download dos arquivos para o servidor EC2
cd /home/usuario/sistemas-docker

# Executar setup completo
make setup
```

### 2. Configurar senhas
```bash
# Editar arquivo de configuração
nano .env

# Alterar pelo menos estas senhas:
# MYSQL8_ROOT_PASSWORD=SUA_SENHA_FORTE_AQUI
# MYSQL57_ROOT_PASSWORD=SUA_SENHA_FORTE_AQUI
```

### 3. Iniciar sistema
```bash
# Iniciar todos os containers
make start

# Verificar se tudo está OK
make monitor
```

### 4. Configurar auto-start
```bash
# Para iniciar automaticamente quando a EC2 ligar
make autostart
```

### 5. Adicionar primeira aplicação
```bash
# Exemplo: adicionar uma loja online
make add-app APP=loja PHP=php81 DOMAIN=loja.exemplo.com

# Colocar código da aplicação em:
# /sistemas/apps/php81/loja/
```

## 🎯 Comandos Essenciais

```bash
make help           # Ver todos os comandos disponíveis
make status         # Ver status dos containers
make logs           # Ver logs de todos os serviços
make monitor        # Informações detalhadas do sistema
make backup         # Backup dos bancos de dados
make restart        # Reiniciar todo o sistema
```

## 🔧 Solução de Problemas Rápida

### Container não inicia
```bash
make logs-nginx     # ou logs-mysql8, logs-php81, etc.
```

### Aplicação não carrega
1. Verificar se DNS aponta para o IP da EC2
2. Verificar configuração Nginx: `nano nginx/conf.d/app-NOME.conf`
3. Ver logs: `make logs-nginx`

### Banco não conecta
1. Verificar senhas no `.env`
2. Verificar configuração da aplicação Laravel
3. Ver logs: `make logs-mysql8`

### Erro de permissão
```bash
sudo chown -R $USER:$USER /sistemas
```

## 📊 Estrutura de Arquivos Importantes

```
📁 docker-compose.yml          # Configuração principal
📁 .env                        # Senhas e configurações
📁 nginx/conf.d/               # Configurações dos sites
📁 /sistemas/apps/             # Códigos das aplicações
📁 /sistemas/mysql8/data/      # Dados MySQL 8.0
📁 /sistemas/mysql57/data/     # Dados MySQL 5.7
📁 scripts/                    # Scripts de gerenciamento
```

## 🌐 Configuração DNS

Para cada aplicação, configure o DNS:
```
app.exemplo.com     A    IP-DA-SUA-EC2
loja.exemplo.com    A    IP-DA-SUA-EC2
blog.exemplo.com    A    IP-DA-SUA-EC2
```

## 🔒 Segurança Básica

### Para produção, altere:
1. **Senhas**: Todas no arquivo `.env`
2. **Certificados SSL**: Substitua os auto-assinados por válidos
3. **Firewall**: Abra apenas portas 80, 443 e 22
4. **Backup**: Configure backup automático

### Comandos de segurança:
```bash
# Trocar senhas MySQL
docker exec mysql8 mysql -uroot -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'nova_senha';"

# Verificar portas abertas
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

## 📈 Monitoramento

### Verificar recursos:
```bash
make monitor        # Informações completas
docker stats        # Uso em tempo real
df -h /sistemas/    # Espaço em disco
```

### Logs importantes:
```bash
tail -f logs/nginx/access.log    # Acessos HTTP
tail -f logs/nginx/error.log     # Erros Nginx
make logs-mysql8                 # Logs banco principal
```

## 🚨 Backup e Restore

### Backup automático:
```bash
make backup                      # Backup manual
crontab -e                       # Adicionar linha:
# 0 2 * * * cd /caminho/para/projeto && make backup
```

### Restore:
```bash
# Restaurar MySQL 8.0
docker exec -i mysql8 mysql -uroot -p < /sistemas/backups/backup.sql

# Restaurar aplicação
cp -r /backup/app/ /sistemas/apps/php81/app/
```

---

## ⚡ Resumo de 30 segundos

```bash
# 1. Setup inicial
make setup

# 2. Editar senhas
nano .env

# 3. Iniciar sistema  
make start

# 4. Verificar
make status

# 5. Adicionar app
make add-app APP=meusite PHP=php81 DOMAIN=meusite.com

# Pronto! 🎉
```

**Suporte**: Para dúvidas, execute `./scripts/test-system.sh` para diagnóstico automático.
