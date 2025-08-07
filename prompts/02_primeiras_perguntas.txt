# Perguntas Pendentes - Refinamento da Implementação

## Contexto
Sistema de containerização criado com sucesso na versão 1.0.0.
As perguntas abaixo são para refinar a implementação conforme necessidades específicas do projeto.

## 📝 Perguntas para Refinamento

### 1. **Versões do PHP** ✅ RESPONDIDO
Além do PHP 5.6 para sistemas legados, quais outras versões do PHP você pretende usar?
- [x] PHP 5.6 (incluído) - Sistemas legados
- [x] PHP 7.4 (incluído) - Última versão 7
- [x] PHP 8.1 (incluído) - Última versão 8
- [ ] PHP 8.0
- [ ] PHP 8.2
- [ ] PHP 8.3

**RESPOSTA**: PHP 5.6, última 7 (7.4) e última 8 (8.1) - já implementado ✅

### 2. **Roteamento no Nginx** ✅ RESPONDIDO
Como você gostaria que o nginx roteie as requisições para as diferentes aplicações?
- [x] Por subdomínio (app1.dominio.com, app2.dominio.com) - **Implementado**
- [x] Por domínio (dominio1.com, dominio2.com) - Para clientes específicos
- [ ] Por path (/app1, /app2)
- [ ] Estratégia mista

**RESPOSTA**: Roteamento por domínio (via Cloudflare) ou subdomínio para clientes específicos - implementar ambos ✅

### 3. **SSL/HTTPS** ✅ RESPONDIDO
Como planeja gerenciar os certificados SSL?
- [x] Certificados auto-assinados (desenvolvimento) - **Implementado**
- [x] Let's Encrypt automático - **A IMPLEMENTAR** (certbot)
- [ ] Certificados comerciais manuais
- [ ] AWS Certificate Manager
- [ ] Cloudflare SSL

**RESPOSTA**: Let's Encrypt com certbot - criar implementação automática ⏳

### 4. **Versões do MySQL** ✅ RESPONDIDO
Além do MySQL 8.0 e 5.7, há necessidade de outras versões?
- [x] MySQL 8.0 - **Implementado** (mais recente)
- [x] MySQL 5.7 - **Implementado** (legado)
- [ ] MySQL 5.6
- [ ] MariaDB
- [ ] PostgreSQL

**RESPOSTA**: MySQL 5.7 e mais recente (8.0) - já implementado ✅

### 5. **Estrutura de Diretórios** ✅ RESPONDIDO
No diretório `/sistemas`, a organização atual atende?

**ESTRUTURA ATUAL:**
```
/sistemas/
├── apps/php81/          # Aplicações PHP 8.1
├── apps/php74/          # Aplicações PHP 7.4
├── apps/php56/          # Aplicações PHP 5.6
├── mysql8/data/         # Dados MySQL 8.0
├── mysql57/data/        # Dados MySQL 5.7
├── redis/data/          # Dados Redis
└── backups/             # Backups
```

**ESTRUTURA PROPOSTA (melhorada):**
```
/sistemas/
├── docker-containers/          # Projeto Docker (este repositório)
│   ├── docker-compose.yml
│   ├── nginx/
│   ├── scripts/
│   └── ...
├── apps/                      # Aplicações por versão PHP
│   ├── php81/
│   │   ├── app1/
│   │   ├── app2/
│   │   └── ...
│   ├── php74/
│   │   ├── legacy-app/
│   │   └── ...
│   └── php56/
│       ├── very-old-app/
│       └── ...
├── databases/                 # Dados dos bancos
│   ├── mysql8/
│   │   ├── data/
│   │   ├── conf/
│   │   └── logs/
│   └── mysql57/
│       ├── data/
│       ├── conf/
│       └── logs/
├── cache/                     # Cache e sessões
│   └── redis/
│       └── data/
├── backups/                   # Backups organizados
│   ├── daily/
│   ├── weekly/
│   ├── monthly/
│   └── apps/
├── ssl/                       # Certificados SSL
│   ├── letsencrypt/
│   ├── domains/
│   └── temp/
└── logs/                      # Logs centralizados
    ├── nginx/
    ├── php/
    ├── mysql/
    └── system/
```

**RESPOSTA**: Estrutura proposta acima - organizada e escalável ⏳

### 6. **Recursos e Performance** ✅ RESPONDIDO
A t3a.small tem 2 vCPUs e 2GB RAM. Estimativa de aplicações simultâneas:
- [ ] 1-3 aplicações pequenas
- [ ] 4-6 aplicações pequenas
- [ ] 7-10 aplicações pequenas
- [ ] Mais de 10 aplicações
- [ ] Aplicações com alto tráfego

**RESPOSTA**: Não se preocupar com isso por ora - configurações atuais são adequadas ✅

---

## 🎯 PRÓXIMAS IMPLEMENTAÇÕES BASEADAS NAS RESPOSTAS

### 1. **Let's Encrypt com Certbot** ⏳
- Implementar script automático para certificados SSL
- Renovação automática via cron
- Suporte a múltiplos domínios

### 2. **Roteamento por Domínio** ⏳
- Configurar Nginx para domínios principais (não apenas subdomínios)
- Templates para configuração rápida
- Integração com Cloudflare

### 3. **Estrutura de Diretórios Melhorada** ⏳
- Reorganizar `/sistemas` conforme proposta
- Script de migração da estrutura atual
- Melhor organização de logs e backups

### 4. **Script de Setup Completo** ⏳
- Atualizar script de setup para nova estrutura
- Incluir configuração Let's Encrypt
- Setup automático de domínios