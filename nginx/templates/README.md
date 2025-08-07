# Templates Nginx

Este diretório contém os templates base para criação automática de configurações Nginx.

## 📁 Estrutura

```
nginx/
├── conf.d/                     # Configurações ATIVAS (carregadas pelo Nginx)
│   └── app-*.conf             # Aplicações em produção
├── templates/                  # Templates do sistema (NÃO carregados)
│   ├── php56-http-template.conf   # Template HTTP para PHP 5.6
│   ├── php56-https-template.conf  # Template HTTPS para PHP 5.6
│   ├── php74-http-template.conf   # Template HTTP para PHP 7.4
│   ├── php74-https-template.conf  # Template HTTPS para PHP 7.4
│   ├── php84-http-template.conf   # Template HTTP para PHP 8.4
│   ├── php84-https-template.conf  # Template HTTPS para PHP 8.4
│   └── README.md              # Esta documentação
├── examples/                   # Exemplos e documentação
└── ssl/                       # Certificados SSL
```

## 🔧 Como Funciona

Os arquivos neste diretório servem como **templates base** e **NÃO são carregados pelo Nginx**.

### Variáveis de Substituição

Cada template contém variáveis que são automaticamente substituídas pelo script `add-app.sh`:

- `{{APP_NAME}}` - Nome da aplicação
- `{{DOMAIN}}` - Domínio principal
- `{{PHP_VERSION}}` - Versão do PHP (php56, php74, php84)

### Exemplo de Uso

```bash
# O script usa automaticamente o template correto
./scripts/add-app.sh minha-loja php84 loja.exemplo.com
```

Isso criará um arquivo `nginx/conf.d/app-minha-loja.conf` baseado no template `php84-template.conf`.

## 📋 Características dos Templates

### PHP 8.4 (Moderno)
- Security headers completos
- Timeouts otimizados (60s)
- Buffers grandes para performance
- Suporte completo a Laravel

### PHP 7.4 (Estável)
- Configuração equilibrada
- Timeouts otimizados (60s)
- Buffers médios
- Suporte completo a Laravel

### PHP 5.6 (Legado)
- Headers de segurança compatíveis
- Timeouts conservadores (30s)
- Buffers menores
- Compatibilidade com apps antigas

## 🛡️ Segurança

Todos os templates incluem:
- Redirecionamento HTTP → HTTPS
- Headers de segurança apropriados
- Rate limiting
- Proteção de arquivos sensíveis (.env, .git, etc.)
- Logs específicos por aplicação

## ⚠️ Importante

- **NUNCA edite diretamente os arquivos em `conf.d/`**
- Use sempre o script `add-app.sh` para criar novas aplicações
- Modifique os templates se precisar de mudanças globais
- O Nginx **NÃO carrega** os arquivos desta pasta
