#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/ubuntu/AlimentosYBebidas"
PYTHON_BIN="python3.12"

sudo apt-get update
sudo apt-get install -y \
  python3-pip \
  python3.12-venv \
  python3.12-dev \
  build-essential \
  nginx \
  snapd \
  libmagic1

if ! snap list core >/dev/null 2>&1; then
  sudo snap install core
fi

sudo snap refresh core

if ! snap list certbot >/dev/null 2>&1; then
  sudo snap install --classic certbot
fi

sudo ln -sf /snap/bin/certbot /usr/bin/certbot

cd "$PROJECT_DIR"

if [ ! -d ".venv" ]; then
  "$PYTHON_BIN" -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip wheel
pip install -r requirements.txt

mkdir -p app/static/evidencias app/static/firmas app/static/img/firmas
sudo chown -R ubuntu:www-data app/static/evidencias app/static/firmas app/static/img/firmas
sudo chmod -R 775 app/static/evidencias app/static/firmas app/static/img/firmas

echo "Bootstrap base completado."
echo "Siguiente paso: copiar /etc/alimentosybebidas.env, systemd y nginx según deploy/ec2/README.md"
