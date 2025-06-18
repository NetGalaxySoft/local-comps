#!/bin/bash

echo "🚀 Стартиране на инсталационен скрипт за NetGalaxyCP/UP среда..."
echo "------------------------------------------------------------"

# Обновяване на системата
sudo apt update && sudo apt upgrade -y

# Основни инструменти
sudo apt install -y build-essential curl wget git unzip zip nano htop \
  software-properties-common ca-certificates gnupg lsb-release mc

echo
echo "🧰 Инсталиране на Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

echo
echo "🌐 Инсталиране на Brave браузър..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave.com/static-assets/archive.key
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave.com/linux/ stable main" | \
sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
sudo apt update
sudo apt install -y brave-browser

echo
echo "🌍 Инсталиране на Google Chrome..."
wget -qO chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./chrome.deb
rm chrome.deb

echo
echo "🛡️ Инсталиране на Tor Browser..."
sudo apt install -y tor torsocks
wget https://www.torproject.org/dist/torbrowser/13.0.13/tor-browser-linux64-13.0.13_ALL.tar.xz
tar -xf tor-browser-linux64-13.0.13_ALL.tar.xz
rm tor-browser-linux64-13.0.13_ALL.tar.xz
mv tor-browser* ~/TorBrowser
~/TorBrowser/start-tor-browser.desktop --register-app

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

# Инсталиране на основни пакети Python 
pip install --upgrade pip
pip install fastapi uvicorn[standard] jinja2 python-multipart

echo
echo "✅ Готово! Средата за разработка на NetGalaxyCP/UP е настроена."
echo "➡️  За да започнете работа, използвайте следния код:"
echo "   cd ~/NetGalaxyUP"
echo ""
echo "   За излизане от режим (venv) използвайте командата:"
echo "   deactivate"

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
