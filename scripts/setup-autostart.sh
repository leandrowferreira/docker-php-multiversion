#!/bin/bash

# Script para configurar auto-start do sistema de containers
# Este script configura um serviço systemd para iniciar automaticamente

set -e

SERVICE_NAME="sistemas-docker"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
DOCKER_COMPOSE_PATH="$(pwd)"

echo "🚀 Configurando auto-start do sistema de containers..."

# Criar o arquivo de serviço systemd
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Sistemas Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DOCKER_COMPOSE_PATH
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar o serviço
sudo systemctl enable "$SERVICE_NAME"

echo "✅ Serviço $SERVICE_NAME configurado com sucesso!"
echo ""
echo "🔧 Comandos úteis:"
echo "  sudo systemctl start $SERVICE_NAME    - Iniciar manualmente"
echo "  sudo systemctl stop $SERVICE_NAME     - Parar manualmente"
echo "  sudo systemctl status $SERVICE_NAME   - Ver status"
echo "  sudo systemctl disable $SERVICE_NAME  - Desabilitar auto-start"
echo ""
echo "ℹ️  O sistema agora iniciará automaticamente quando a EC2 for ligada."
