#!/bin/bash

echo "🚀 Стартиране на инсталационен скрипт за NetGalaxyUP среда..."
echo "------------------------------------------------------------"

# Обновяване на системата
sudo apt update && sudo apt upgrade -y

# Основни инструменти
sudo apt install -y build-essential curl wget git unzip zip nano htop \
  software-properties-common ca-certificates gnupg lsb-release mc

# Python и виртуална среда
sudo apt install -y python3 python3-pip python3-venv

# Node.js (LTS версия)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn vite

# GitHub CLI
sudo apt install -y gh

# Бази данни (клиенти)
sudo apt install -y postgresql-client mysql-client

# Pandoc за документации
sudo apt install -y pandoc

# Docker (по избор)
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker "$USER"

# Създаване на директория и виртуална среда за проекта NetGalaxyUP
mkdir -p ~/NetGalaxyUP && cd ~/NetGalaxyUP
python3 -m venv venv
source venv/bin/activate

# Инсталиране на основни Python пакети
pip install --upgrade pip
pip install fastapi uvicorn[standard] jinja2 python-multipart

echo
echo "✅ Готово! Средата за разработка на NetGalaxyUP е настроена."
echo "➡️  За да започнеш работа:"
echo "   cd ~/NetGalaxyUP"
echo "   source venv/bin/activate"

# Почистване: изтриване на скрипта, ако е локално копие
echo
echo "🧹 Почистване: премахване на скрипта от системата..."

SCRIPT_PATH="$(realpath "$0")"

# Проверка дали скриптът не е в Git хранилище
if [[ "$SCRIPT_PATH" != *".git"* && "$SCRIPT_PATH" != *"/local-comps/"* ]]; then
    echo "🗑️  Изтриване на: $SCRIPT_PATH"
    rm -f "$SCRIPT_PATH"
else
    echo "📌 Скриптът е част от Git хранилище – няма да бъде изтрит автоматично."
fi
