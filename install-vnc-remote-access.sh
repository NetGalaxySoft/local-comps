#!/bin/bash

# ============================================================================
# 📦 install-vnc-remote-access.sh (без пароли)
# ----------------------------------------------------------------------------
# Инсталира XFCE + TigerVNC с clipboard sync, достъпен без парола
# ============================================================================
# Предназначен за вътрешни или обучителни машини, без нужда от автентикация.
# ============================================================================

echo "🖥️ Инсталация на XFCE + TigerVNC (без пароли)..."
echo "-------------------------------------------------------------------------"

# Проверка за root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Скриптът трябва да се изпълни с root права (sudo)."
  exit 1
fi

USER_HOME=$(eval echo "~$SUDO_USER")
USER_VNC_DIR="$USER_HOME/.vnc"

# Инсталиране на нужните пакети
apt update && apt install -y \
  xfce4 xfce4-goodies \
  tigervnc-standalone-server \
  autocutsel

# Създаване на .vnc директория
sudo -u "$SUDO_USER" mkdir -p "$USER_VNC_DIR"

# Конфигуриране на xstartup
cat > "$USER_VNC_DIR/xstartup" << 'EOF'
#!/bin/sh
xrdb $HOME/.Xresources
autocutsel -fork
startxfce4 &
EOF

chmod +x "$USER_VNC_DIR/xstartup"
chown "$SUDO_USER":"$SUDO_USER" "$USER_VNC_DIR/xstartup"

# Изтриване на стара парола и конфигуриране на "без защита"
sudo -u "$SUDO_USER" rm -f "$USER_VNC_DIR/passwd"

# Конфигурация на permanent securitytypes=none
cat > "$USER_VNC_DIR/config" <<EOF
securitytypes=none
EOF

chown "$SUDO_USER":"$SUDO_USER" "$USER_VNC_DIR/config"

# Старт и стоп за инициализация
echo "🚀 Инициализация на VNC..."
sudo -u "$SUDO_USER" vncserver :1
sudo -u "$SUDO_USER" vncserver -kill :1

# Финално съобщение
echo
echo "✅ VNC сървърът е конфигуриран без парола."
echo "📎 Свържи се на: <IP>:5901"
echo "🛡️ За достъп без интернет риск, препоръчително е да работи само през VPN или защитена мрежа."
echo ""
echo "▶️ Старт:   vncserver :1"
echo "⛔ Стоп:    vncserver -kill :1"

