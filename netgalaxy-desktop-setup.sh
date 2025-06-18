#!/bin/bash

echo "🖥️ Стартиране на скрипт за инсталиране на Plasma X11 и офис среда..."
echo "------------------------------------------------------------"

# Обновяване на системата
sudo apt update && sudo apt upgrade -y

# Инсталиране на графична среда (Plasma + display manager)
sudo apt install -y kde-standard sddm

# Инсталиране на офис софтуер с български език
sudo apt install -y libreoffice libreoffice-l10n-bg libreoffice-help-bg

# Пощенски клиент
sudo apt install -y thunderbird

# Уеб браузър: Brave
if ! command -v brave-browser &> /dev/null; then
  echo "🌐 Инсталиране на Brave браузър..."
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave.com/static-assets/archive.key
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave.com/linux/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
  sudo apt update
  sudo apt install -y brave-browser
else
  echo "✅ Brave вече е инсталиран."
fi

# Уеб браузър: Google Chrome
if ! command -v google-chrome &> /dev/null; then
  echo "🌍 Инсталиране на Google Chrome..."
  wget -qO chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y ./chrome.deb
  rm chrome.deb
else
  echo "✅ Google Chrome вече е инсталиран."
fi

# Visual Studio Code
if ! command -v code &> /dev/null; then
  echo "🧰 Инсталиране на Visual Studio Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt update
  sudo apt install -y code
else
  echo "✅ Visual Studio Code вече е инсталиран."
fi

# Tor Browser
if [ ! -d "$HOME/TorBrowser" ]; then
  echo "🛡️ Инсталиране на Tor Browser..."
  sudo apt install -y tor torsocks
  wget https://www.torproject.org/dist/torbrowser/13.0.13/tor-browser-linux64-13.0.13_ALL.tar.xz
  tar -xf tor-browser-linux64-13.0.13_ALL.tar.xz
  rm tor-browser-linux64-13.0.13_ALL.tar.xz
  mv tor-browser* ~/TorBrowser
  ~/TorBrowser/start-tor-browser.desktop --register-app
else
  echo "✅ Tor Browser вече е инсталиран."
fi

# Допълнителни полезни инструменти
sudo apt install -y okular ark

# Почистване на ненужни пакети
sudo apt autoremove -y

echo
echo "✅ Графичната среда Plasma X11 и офис приложенията са успешно инсталирани."
echo "➡️ Рестартирайте системата, за да заредите графичната сесия."
