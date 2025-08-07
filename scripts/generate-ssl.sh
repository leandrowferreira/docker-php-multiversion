#!/bin/bash

# Script para gerar certificados SSL auto-assinados para desenvolvimento
# Em produção, use Let's Encrypt ou certificados válidos

set -e

SSL_DIR="nginx/ssl"
mkdir -p "$SSL_DIR"

echo "🔐 Gerando certificados SSL auto-assinados..."

# Gerar chave privada
openssl genrsa -out "$SSL_DIR/key.pem" 2048

# Gerar certificado auto-assinado
openssl req -new -x509 -key "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem" -days 365 \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=Desenvolvimento/CN=*.exemplo.com"

# Ajustar permissões
chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"

echo "✅ Certificados SSL criados:"
echo "   Certificado: $SSL_DIR/cert.pem"
echo "   Chave privada: $SSL_DIR/key.pem"
echo ""
echo "⚠️  ATENÇÃO: Estes são certificados auto-assinados para desenvolvimento!"
echo "   Para produção, use certificados válidos ou Let's Encrypt."
