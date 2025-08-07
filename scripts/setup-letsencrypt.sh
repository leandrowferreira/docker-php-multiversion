#!/bin/bash

# Script para configurar Let's Encrypt com Certbot
# Suporta múltiplos domínios e subdomínios
# Inclui renovação automática

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Função para mostrar ajuda
show_help() {
    echo "🔐 Script de configuração Let's Encrypt"
    echo "======================================"
    echo ""
    echo "Uso: $0 [OPÇÕES] DOMINIO [DOMINIO2] [DOMINIO3]..."
    echo ""
    echo "Opções:"
    echo "  -e EMAIL     Email para registro no Let's Encrypt (obrigatório)"
    echo "  -d           Modo dry-run (teste sem gerar certificados)"
    echo "  -r           Apenas renovar certificados existentes"
    echo "  -s           Modo staging (certificados de teste)"
    echo "  -h           Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -e admin@exemplo.com exemplo.com www.exemplo.com"
    echo "  $0 -e admin@exemplo.com -s app.exemplo.com"
    echo "  $0 -r  # Renovar todos os certificados"
    echo ""
}

# Variáveis padrão
EMAIL=""
DRY_RUN=false
RENEW_ONLY=false
STAGING=false
DOMAINS=()

# Parse dos argumentos
while getopts "e:drsh" opt; do
    case $opt in
        e)
            EMAIL="$OPTARG"
            ;;
        d)
            DRY_RUN=true
            ;;
        r)
            RENEW_ONLY=true
            ;;
        s)
            STAGING=true
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            error "Opção inválida: -$OPTARG"
            show_help
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))
DOMAINS=("$@")

# Verificações iniciais
if [ "$RENEW_ONLY" = false ] && [ -z "$EMAIL" ]; then
    error "Email é obrigatório para novos certificados"
    show_help
    exit 1
fi

if [ "$RENEW_ONLY" = false ] && [ ${#DOMAINS[@]} -eq 0 ]; then
    error "Pelo menos um domínio deve ser especificado"
    show_help
    exit 1
fi

echo "🔐 Configurando Let's Encrypt"
echo "============================"
info "Email: $EMAIL"
info "Domínios: ${DOMAINS[*]}"
info "Dry-run: $DRY_RUN"
info "Staging: $STAGING"
info "Renovar apenas: $RENEW_ONLY"
echo ""

# Verificar se certbot está instalado
if ! command -v certbot >/dev/null 2>&1; then
    warning "Certbot não encontrado. Instalando..."
    
    # Detectar sistema operacional
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y certbot python3-certbot-nginx
    else
        error "Sistema operacional não suportado para instalação automática"
        error "Instale o certbot manualmente: https://certbot.eff.org/"
        exit 1
    fi
    
    success "Certbot instalado"
fi

# Verificar se nginx está rodando
if ! docker ps | grep -q nginx-proxy; then
    error "Container nginx-proxy não está rodando"
    error "Execute: docker-compose up -d nginx"
    exit 1
fi

# Criar diretórios necessários
mkdir -p /sistemas/ssl/letsencrypt
mkdir -p /sistemas/ssl/domains

# Função para renovar certificados
renew_certificates() {
    info "Renovando certificados existentes..."
    
    if certbot renew --nginx --quiet; then
        success "Certificados renovados com sucesso"
        
        # Recarregar nginx
        docker exec nginx-proxy nginx -s reload
        success "Nginx recarregado"
    else
        error "Erro ao renovar certificados"
        return 1
    fi
}

# Função para obter novos certificados
obtain_certificates() {
    local domains_str=""
    for domain in "${DOMAINS[@]}"; do
        domains_str="$domains_str -d $domain"
    done
    
    # Construir comando certbot
    local certbot_cmd="certbot --nginx"
    
    if [ "$DRY_RUN" = true ]; then
        certbot_cmd="$certbot_cmd --dry-run"
    fi
    
    if [ "$STAGING" = true ]; then
        certbot_cmd="$certbot_cmd --staging"
    fi
    
    certbot_cmd="$certbot_cmd --email $EMAIL --agree-tos --non-interactive"
    certbot_cmd="$certbot_cmd $domains_str"
    
    info "Executando: $certbot_cmd"
    
    if eval $certbot_cmd; then
        if [ "$DRY_RUN" = false ]; then
            success "Certificados obtidos com sucesso!"
            
            # Recarregar nginx
            docker exec nginx-proxy nginx -s reload
            success "Nginx recarregado"
            
            # Salvar informações dos domínios
            for domain in "${DOMAINS[@]}"; do
                echo "$(date): Certificado criado para $domain" >> /sistemas/ssl/domains/certificates.log
            done
        else
            success "Dry-run concluído com sucesso!"
        fi
    else
        error "Erro ao obter certificados"
        return 1
    fi
}

# Configurar renovação automática
setup_auto_renewal() {
    info "Configurando renovação automática..."
    
    # Criar script de renovação
    cat > /sistemas/ssl/renew-certs.sh << 'EOF'
#!/bin/bash
# Script de renovação automática dos certificados Let's Encrypt

LOG_FILE="/sistemas/logs/ssl/renewal.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Iniciando renovação automática" >> "$LOG_FILE"

# Renovar certificados
if certbot renew --nginx --quiet >> "$LOG_FILE" 2>&1; then
    echo "$(date): Certificados renovados com sucesso" >> "$LOG_FILE"
    
    # Recarregar nginx se estiver rodando
    if docker ps | grep -q nginx-proxy; then
        docker exec nginx-proxy nginx -s reload >> "$LOG_FILE" 2>&1
        echo "$(date): Nginx recarregado" >> "$LOG_FILE"
    fi
else
    echo "$(date): ERRO na renovação de certificados" >> "$LOG_FILE"
fi

echo "$(date): Renovação concluída" >> "$LOG_FILE"
EOF

    chmod +x /sistemas/ssl/renew-certs.sh
    
    # Adicionar ao crontab se não existir
    if ! crontab -l 2>/dev/null | grep -q "renew-certs.sh"; then
        (crontab -l 2>/dev/null; echo "0 2 * * * /sistemas/ssl/renew-certs.sh") | crontab -
        success "Renovação automática configurada (diariamente às 2h)"
    else
        warning "Renovação automática já configurada"
    fi
}

# Função principal
main() {
    if [ "$RENEW_ONLY" = true ]; then
        renew_certificates
    else
        obtain_certificates
        
        if [ "$DRY_RUN" = false ]; then
            setup_auto_renewal
        fi
    fi
    
    echo ""
    info "📋 Informações úteis:"
    echo "  - Certificados: /etc/letsencrypt/live/"
    echo "  - Logs: /var/log/letsencrypt/"
    echo "  - Renovação manual: certbot renew"
    echo "  - Status: certbot certificates"
    echo ""
    
    if [ "$DRY_RUN" = false ] && [ "$RENEW_ONLY" = false ]; then
        success "🎉 Let's Encrypt configurado com sucesso!"
        warning "⚠️  Lembre-se de configurar as portas 80 e 443 no Security Group da EC2"
    fi
}

# Executar função principal
main
