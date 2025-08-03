#!/bin/bash
# ==========================================================================
#  unicyrl-dev-setup.sh – Скрипт за модулно изграждане на UniCyrl v1.0
# --------------------------------------------------------------------------
#  Версия: 1.0
#  Дата: 2025-08-03
#  Автор: Ilko Yordanov / NetGalaxy
# ==========================================================================
#
#  Цел:
#    - Постепенно изграждане на системата UniCyrl чрез отделни модули.
#    - Запазване на целия процес на разработка с образователна стойност.
#    - Използване като демонстрационен инструмент за обучение по програмиране.
#
#  Зависимости:
#    - Работеща Linux система с bash shell.
#    - Потребителски права за запис в локалната директория.
#    - Python 3, Autokey (или Xlib), Zenity/Rofi (по избор).
#
# ==========================================================================

# === ПОМОЩНА ИНФОРМАЦИЯ ===================================================
show_help() {
  echo ""
  echo "Използване: unicyrl-dev-setup.sh [опция]"
  echo ""
  echo "Модулно изграждане на системата UniCyrl с цел демонстрация и обучение."
  echo ""
  echo "Опции:"
  echo "  --version       Показва версията на скрипта"
  echo "  --help          Показва тази помощ"
  echo ""
  echo "Забележка: Скриптът е самодостатъчен и изпълнява всички модули последователно."
  echo ""
}
# === ОБРАБОТКА НА ОПЦИИ ====================================================
if [[ $# -gt 0 ]]; then
  case "$1" in
    --version)
      echo "unicyrl-dev-setup.sh версия 1.0 (3 август 2025 г.)"
      exit 0
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "❌ Неразпозната опция: $1"
      show_help
      exit 1
      ;;
  esac
fi

# === ПРОВЕРКА ЗА ПРЕДХОДНО ИЗПЪЛНЕНИЕ НА СКРИПТА ========================

NETGALAXY_DIR="/etc/netgalaxy"
SETUP_ENV_FILE="$NETGALAXY_DIR/setup.env"
MODULES_FILE="$NETGALAXY_DIR/todo.modules"

# 🛡️ Функции за защита и отключване на setup.env
unlock_setup_env() { sudo chattr -i "$SETUP_ENV_FILE"; }
lock_setup_env()   { sudo chattr +i "$SETUP_ENV_FILE"; }


# Създаване на директорията, ако не съществува
if [ ! -d "$NETGALAXY_DIR" ]; then
  sudo mkdir -p "$NETGALAXY_DIR"
fi

# Създаване на файла setup.env, ако не съществува
if [ ! -f "$SETUP_ENV_FILE" ]; then
  sudo touch "$SETUP_ENV_FILE"
  # Защита от изтриване (immutable)
  sudo chattr +i "$SETUP_ENV_FILE"
fi

# Създаване на файла, ако не съществува
if [ ! -f "$SETUP_ENV_FILE" ]; then
  sudo touch "$SETUP_ENV_FILE"
  sudo chattr +i "$SETUP_ENV_FILE"   # ⛔ Забрана за изтриване, разрешено писане чрез unlock/lock
fi

# Проверка дали скриптът вече е изпълнен успешно
if grep -q '^UNICYRL_SCRIPT=✅' "$SETUP_ENV_FILE"; then
  echo "✅ Скриптът вече е изпълнен успешно. Прекратяване..."
  exit 0
fi

# =====================================================================
# [МОДУЛ 1] ПРЕДВАРИТЕЛНИ ПРОВЕРКИ И НАСТРОЙКА НА РАБОТНА СРЕДА
# =====================================================================
echo "[1] ПРЕДВАРИТЕЛНИ ПРОВЕРКИ И НАСТРОЙКА НА РАБОТНА СРЕДА..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE1=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 1 вече е изпълнен успешно. Пропускане..."
  echo ""
else

# === Проверка за зависимости ===
REQUIRED_CMDS=("bash" "python3" "jq")

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "🔧 Липсва $cmd – опит за автоматична инсталация..."
    if sudo apt update && sudo apt install -y "$cmd"; then
      echo "✅ Успешно инсталиран $cmd."
    else
      echo "❌ Неуспешна автоматична инсталация на $cmd. Прекратяване."
      exit 1
    fi
  else
    echo "✅ $cmd вече е наличен."
  fi
done

echo "✅ Всички зависимости са налични."

# === Създаване на проектна директория ===
mkdir -p ./build
echo "📁 Създадена е работна директория: ./build"

# === Създаване на празна таблица за map-101.json (ще се попълни по-късно) ===
cat > ./build/map-101.json <<EOF
{
  // TODO: Ще бъде попълнено в МОДУЛ 2
}
EOF
echo "📄 Създаден файл: build/map-101.json"

# === Създаване на config.json с настройки по подразбиране ===
cat > ./build/config.json <<EOF
{
  "escape_key": "LeftAlt",
  "preferred_currency": "€",
  "recent_currencies": ["€", "$", "лв"]
}
EOF
echo "⚙️  Създаден файл: build/config.json"

# === Създаване на примерен currencies.csv ===
cat > ./build/currencies.csv <<EOF
symbol,code,name
€,EUR,Евро
$,USD,Щатски долар
лв,BGN,Български лев
₽,RUB,Руска рубла
¥,CNY,Китайски юан
₴,UAH,Украинска гривна
EOF
echo "💱 Създаден файл: build/currencies.csv"

# === Защита на setup.env и записване на резултата ===
if sudo grep -q '^UNICYRL_MODULE1=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  sudo sed -i 's|^UNICYRL_MODULE1=.*|UNICYRL_MODULE1=✅|' "$SETUP_ENV_FILE"
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE1=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE. Прекратяване."
    exit 1
  fi
  lock_setup_env
fi

echo ""
echo "✅ Модул 1 е завършен успешно."

fi
echo ""
echo ""


# =====================================================================
# [МОДУЛ 2] СЪЗДАВАНЕ НА map-101.json
# =====================================================================
echo "[2] СЪЗДАВАНЕ НА map-101.json..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE2=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 2 вече е изпълнен успешно. Пропускане..."
  echo ""
else

  MAP_FILE="./build/map-101.json"

  cat > "$MAP_FILE" <<EOF
{
  "a": "а",
  "b": "б",
  "v": "в",
  "g": "г",
  "d": "д",
  "e": "е",
  "e'": "э",
  "e''": "ё",
  "zh": "ж",
  "w": "ж",
  "z": "з",
  "i": "и",
  "i'": "ѝ",
  "i''": "и́",
  "j": "й",
  "k": "к",
  "l": "л",
  "m": "м",
  "n": "н",
  "o": "о",
  "p": "п",
  "r": "р",
  "s": "с",
  "t": "т",
  "u": "у",
  "f": "ф",
  "h": "х",
  "c": "ц",
  "ch": "ч",
  "x": "ч",
  "sh": "ш",
  "[": "ш",
  "sht": "щ",
  "]": "щ",
  "y": "ъ",
  "\`": "ь",
  ";": "ы",
  "\\\\": "ю",
  "q": "я"
}
EOF

  echo "📄 Файлът map-101.json е създаден успешно в: $MAP_FILE"

# ✅ Запис в setup.env
if sudo grep -q '^UNICYRL_MODULE2=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  if ! sudo sed -i 's|^UNICYRL_MODULE2=.*|UNICYRL_MODULE2=✅|' "$SETUP_ENV_FILE"; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE2=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при добавяне в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
fi


  # ✅ Запис в todo.modules
  if sudo grep -q '^MAP_FILE=' "$MODULES_FILE"; then
    if ! sudo sed -i "s|^MAP_FILE=.*|MAP_FILE=$MAP_FILE|" "$MODULES_FILE"; then
      echo "❌ Грешка при актуализация на MAP_FILE в $MODULES_FILE"
      exit 1
    fi
  else
    if ! sudo sh -c "echo 'MAP_FILE=$MAP_FILE' >> '$MODULES_FILE'"; then
      echo "❌ Грешка при добавяне на MAP_FILE в $MODULES_FILE"
      exit 1
    fi
  fi

  echo ""
  echo "✅ Модул 2 е завършен успешно."

fi
echo ""
echo ""


# =====================================================================
# [МОДУЛ 3] СЪЗДАВАНЕ НА ЛОГИКА ЗА ЧЕТЕНЕ/ЗАПИС НА config.json
# =====================================================================
echo "[3] СЪЗДАВАНЕ НА config_handler.py..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE3=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 3 вече е изпълнен успешно. Пропускане..."
  echo ""
else

CONFIG_SCRIPT="./build/config_handler.py"

cat > "$CONFIG_SCRIPT" <<'EOF'
#!/usr/bin/env python3
import json
import os

CONFIG_FILE = os.path.expanduser("./build/config.json")

# Стойности по подразбиране
DEFAULT_CONFIG = {
    "escape_key": "LeftAlt",
    "preferred_currency": "€",
    "recent_currencies": ["€", "$", "лв"]
}

def load_config():
    if not os.path.exists(CONFIG_FILE):
        save_config(DEFAULT_CONFIG)
        return DEFAULT_CONFIG

    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return DEFAULT_CONFIG

def save_config(config_data):
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"❌ Грешка при запис на config.json: {e}")

def get_setting(key):
    config = load_config()
    return config.get(key, DEFAULT_CONFIG.get(key))

def set_setting(key, value):
    config = load_config()
    config[key] = value
    save_config(config)

# === Тестове (може да се премахнат след вграждане) ===
if __name__ == "__main__":
    print("📂 Текуща настройка за escape_key:", get_setting("escape_key"))
    set_setting("preferred_currency", "₽")
    print("✅ Валутата беше сменена на:", get_setting("preferred_currency"))
EOF

chmod +x "$CONFIG_SCRIPT"
echo "🐍 Създаден Python файл: $CONFIG_SCRIPT"

# ✅ Запис в setup.env
if sudo grep -q '^UNICYRL_MODULE3=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  if ! sudo sed -i 's|^UNICYRL_MODULE3=.*|UNICYRL_MODULE3=✅|' "$SETUP_ENV_FILE"; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE3=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при добавяне в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
fi

# ✅ Запис в todo.modules, че config.json съществува
if sudo grep -q '^CONFIG_JSON=1' "$MODULES_FILE"; then
  sudo sed -i 's|^CONFIG_JSON=.*|CONFIG_JSON=1|' "$MODULES_FILE"
else
  echo "CONFIG_JSON=1" | sudo tee -a "$MODULES_FILE" > /dev/null
fi

echo "✅ Модул 3 е завършен успешно."
echo ""
fi
echo ""
echo ""


# =====================================================================
# [МОДУЛ 4] СЪЗДАВАНЕ НА ОСНОВЕН СЛУШАТЕЛ unicyrl.py
# =====================================================================
echo "[4] СЪЗДАВАНЕ НА unicyrl.py..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE4=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 4 вече е изпълнен успешно. Пропускане..."
  echo ""
else

# === Проверка дали config.json е наличен ===
if ! grep -q '^CONFIG_JSON=1' "$MODULES_FILE"; then
  echo "❌ Липсва предварително генериран config.json. Изпълнете Модул 3."
  echo ""
  exit 1
fi

LISTENER_SCRIPT="./build/unicyrl.py"

cat > "$LISTENER_SCRIPT" <<'EOF'
#!/usr/bin/env python3
import json
import os
import keyboard

MAP_FILE = os.path.expanduser("./build/map-101.json")
CONFIG_FILE = os.path.expanduser("./build/config.json")

# Зареждане на карта
def load_map():
    with open(MAP_FILE, encoding="utf-8") as f:
        return json.load(f)

# Зареждане на конфигурация
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, encoding="utf-8") as f:
            return json.load(f)
    return { "escape_key": "LeftAlt" }

# === НАСТРОЙКИ ===
mapping = load_map()
config = load_config()
escape_key = config.get("escape_key", "LeftAlt")
typed = ""

print("🔠 UniCyrl е активен. Натисни Escape клавиша (по подразбиране: LeftAlt), за да въвеждаш латиница.")

def on_key(event):
    global typed

    if event.event_type != "down":
        return

    key = event.name

    if key == "space":
        typed += " "
        return
    if key == "enter":
        typed = ""
        return
    if key == "backspace":
        typed = typed[:-1]
        return

    # Проверка за активиран escape_key
    if keyboard.is_pressed(escape_key):
        return  # Пропуска преобразуването

    typed += key
    # Проверка за най-дългите ключове (i'', e'', sht и др.)
    for length in sorted(set(len(k) for k in mapping), reverse=True):
        if len(typed) >= length:
            seq = typed[-length:]
            if seq in mapping:
                keyboard.write(mapping[seq])
                typed = typed[:-length]
                break

keyboard.hook(on_key)
keyboard.wait()
EOF

chmod +x "$LISTENER_SCRIPT"
echo "🎧 Създаден Python файл: $LISTENER_SCRIPT"

# ✅ Запис в setup.env
if sudo grep -q '^UNICYRL_MODULE4=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  if ! sudo sed -i 's|^UNICYRL_MODULE4=.*|UNICYRL_MODULE4=✅|' "$SETUP_ENV_FILE"; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE4=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при добавяне в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
fi


# ✅ Запис в todo.modules
if sudo grep -q '^UNICYRL_SCRIPT=' "$MODULES_FILE"; then
  sudo sed -i 's|^UNICYRL_SCRIPT=.*|UNICYRL_SCRIPT=1|' "$MODULES_FILE"
else
  echo "UNICYRL_SCRIPT=1" | sudo tee -a "$MODULES_FILE" > /dev/null
fi

echo "✅ Модул 4 е завършен успешно."
echo ""
fi
echo ""
echo ""


# =====================================================================
# [МОДУЛ 5] СЪЗДАВАНЕ НА currency_select.py
# =====================================================================
echo "[5] СЪЗДАВАНЕ НА currency_select.py..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE5=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 5 вече е изпълнен успешно. Пропускане..."
  echo ""
else

SELECT_SCRIPT="./build/currency_select.py"

cat > "$SELECT_SCRIPT" <<'EOF'
#!/usr/bin/env python3
import os
import json
import csv
import subprocess

CONFIG_FILE = os.path.expanduser("./build/config.json")
CURRENCIES_FILE = os.path.expanduser("./build/currencies.csv")

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}

def save_config(config):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def load_currencies():
    currencies = []
    if os.path.exists(CURRENCIES_FILE):
        with open(CURRENCIES_FILE, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                symbol = row["symbol"]
                name = row["name"]
                currencies.append(f"{symbol} – {name}")
    return currencies

def main():
    config = load_config()
    recent = config.get("recent_currencies", [])
    all_currencies = load_currencies()

    # Подреждане: първо последните, после по азбучен ред
    sorted_currencies = recent + sorted(set(all_currencies) - set(recent))

    # Създаване на списък за zenity
    zenity_list = " ".join(f'"{entry}"' for entry in sorted_currencies)

    # Избор чрез zenity
    try:
        result = subprocess.check_output(
            f"zenity --list --title='Изберете валута' --column='Валути' {zenity_list}",
            shell=True,
            universal_newlines=True
        ).strip()
    except subprocess.CalledProcessError:
        print("❌ Изборът беше прекратен.")
        return

    # Обновяване на config.json
    if result:
        symbol = result.split("–")[0].strip()
        config["preferred_currency"] = symbol
        if "recent_currencies" not in config:
            config["recent_currencies"] = []
        if symbol in config["recent_currencies"]:
            config["recent_currencies"].remove(symbol)
        config["recent_currencies"].insert(0, symbol)
        config["recent_currencies"] = config["recent_currencies"][:5]
        save_config(config)
        print(f"✅ Запазена валута: {symbol}")

if __name__ == "__main__":
    main()
EOF

chmod +x "$SELECT_SCRIPT"
echo "💱 Създаден Python файл: $SELECT_SCRIPT"

# ✅ Запис в setup.env, че модулът е успешен
if sudo grep -q '^UNICYRL_MODULE5=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  sudo sed -i 's|^UNICYRL_MODULE5=.*|UNICYRL_MODULE5=✅|' "$SETUP_ENV_FILE"
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE5=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
fi

echo "✅ Модул 5 е завършен успешно."
echo ""
fi
echo ""
echo ""


# =====================================================================
# [МОДУЛ 6] АВТОМАТИЧНО СТАРТИРАНЕ НА UniCyrl
# =====================================================================
echo "[6] НАСТРОЙКА ЗА АВТОМАТИЧНО СТАРТИРАНЕ..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE6=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 6 вече е изпълнен успешно. Пропускане..."
  echo ""
else

AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/unicyrl.desktop"
SCRIPT_PATH="$HOME/.local/bin/unicyrl.py"

# 1. Копиране на unicyrl.py в ~/.local/bin/
mkdir -p "$HOME/.local/bin"
cp ./build/unicyrl.py "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "📂 Инсталиран unicyrl.py в $SCRIPT_PATH"

# 2. Създаване на autostart директория
mkdir -p "$AUTOSTART_DIR"

# 3. Създаване на .desktop файл
cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=UniCyrl
Comment=Кирилизатор на живо за QWERTY клавиатури
Exec=$SCRIPT_PATH
Icon=accessories-text-editor
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "🖥️ Създаден autostart файл: $AUTOSTART_FILE"

# 4. Проверка за наличност на зависимостта `keyboard`
echo ""
echo "🔧 Проверка за нужните Python зависимости..."
if python3 -c "import keyboard" 2>/dev/null; then
  echo "✅ keyboard вече е наличен – няма нужда от инсталация."
else
  echo "ℹ️ keyboard не е наличен – опит за инсталиране..."
  if ! pip3 install --user keyboard >/dev/null 2>&1; then
    echo "❌ Грешка: неуспешна инсталация на зависимостта 'keyboard'."
    exit 1
  fi

  if ! python3 -c "import keyboard" 2>/dev/null; then
    echo "❌ keyboard все още не е достъпен след инсталация. Прекратяване."
    exit 1
  fi

  echo "✅ keyboard беше успешно инсталиран и е достъпен."
fi

# ✅ Запис в setup.env, че модулът е успешен
if sudo grep -q '^UNICYRL_MODULE6=' "$SETUP_ENV_FILE" 2>/dev/null; then
  unlock_setup_env
  sudo sed -i 's|^UNICYRL_MODULE6=.*|UNICYRL_MODULE6=✅|' "$SETUP_ENV_FILE"
  lock_setup_env
else
  unlock_setup_env
  echo "UNICYRL_MODULE6=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Грешка при запис в $SETUP_ENV_FILE"
    lock_setup_env
    exit 1
  fi
  lock_setup_env
fi

echo ""
echo "✅ Модул 6 е завършен успешно."
echo ""
fi
echo ""
echo ""


exit 0
# =====================================================================
# [МОДУЛ 7] ПАКЕТИРАНЕ НА UniCyrl
# =====================================================================
echo "[7] СЪЗДАВАНЕ НА АРХИВИ С ПРОЕКТА..."
echo "-----------------------------------------------------------"
echo ""

# === Проверка дали модулът вече е изпълнен успешно ===
if sudo grep -q '^UNICYRL_MODULE7=✅' "$SETUP_ENV_FILE"; then
  echo "ℹ️ Модул 7 вече е изпълнен успешно. Пропускане..."
  echo ""
else

ARCHIVE_DIR="$HOME/UniCyrl-archives"
BUILD_DIR="$HOME/UniCyrl"
DATE_TAG=$(date +%Y%m%d-%H%M)

# 1. Създаване на директория за архиви
mkdir -p "$ARCHIVE_DIR"

# 2. Проверка дали build директорията съществува
if [[ ! -d "$BUILD_DIR" ]]; then
  echo "❌ Липсва директорията $BUILD_DIR – не може да се създаде архив!"
  echo ""
  exit 1
fi

# 3. Архивиране като ZIP
ZIP_NAME="unicyrl-$DATE_TAG.zip"
cd "$BUILD_DIR"
zip -r "$ARCHIVE_DIR/$ZIP_NAME" . -x "*.git*" "*__pycache__*" "*.DS_Store*" > /dev/null
echo "📦 ZIP архив създаден: $ARCHIVE_DIR/$ZIP_NAME"

# 4. Архивиране като TAR.GZ
TAR_NAME="unicyrl-$DATE_TAG.tar.gz"
tar --exclude-vcs --exclude='__pycache__' --exclude='.DS_Store' -czf "$ARCHIVE_DIR/$TAR_NAME" . > /dev/null
echo "📦 TAR.GZ архив създаден: $ARCHIVE_DIR/$TAR_NAME"

# ✅ Запис в setup.env, че модулът е успешен
if sudo grep -q '^UNICYRL_MODULE7=' "$SETUP_ENV_FILE"; then
  sudo sed -i 's|^UNICYRL_MODULE7=.*|UNICYRL_MODULE7=✅|' "$SETUP_ENV_FILE"
else
  echo "UNICYRL_MODULE7=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
fi

echo ""
echo "✅ Модул 7 е завършен успешно."
echo ""
fi
echo ""
echo ""


exit 0
# =====================================================================
# [МОДУЛ 8] ОБОБЩЕНИЕ И ФИНАЛЕН ОТЧЕТ
# =====================================================================
echo "[8] ОБОБЩЕНИЕ НА ИЗПЪЛНЕНИЕТО..."
echo "-----------------------------------------------------------"
echo ""

echo "📌 Проект UniCyrl бе създаден в директорията:"
echo "    $HOME/UniCyrl"

echo ""
echo "📦 Архивите се намират тук:"
echo "    $HOME/UniCyrl-archives"

echo ""
echo "🧪 За да стартирате скрипта с трансформация (примерен тест):"
echo "    cd \$HOME/UniCyrl"
echo "    python3 converter.py"

echo ""
echo "ℹ️ За да направите промени по картата на символите, редактирайте:"
echo "    \$HOME/UniCyrl/mapping/unicyrl-map.json"

echo ""
echo "-----------------------------------------------------------"
echo "❓ Приемате ли работата по скрипта за ЗАВЪРШЕНА?"
echo "   Въведете [y] за ДА или [n] за НЕ"
echo "-----------------------------------------------------------"
echo ""

read -rp "Вашият отговор (y/n): " confirm
confirm=${confirm,,}  # Преобразуване в малки букви

if [[ "$confirm" == "y" ]]; then
  # ✅ Обновяване на setup.env
  if sudo grep -q '^UNICYRL_SCRIPT=' "$SETUP_ENV_FILE"; then
    sudo sed -i 's|^UNICYRL_SCRIPT=.*|UNICYRL_SCRIPT=✅|' "$SETUP_ENV_FILE"
  else
    echo "UNICYRL_SCRIPT=✅" | sudo tee -a "$SETUP_ENV_FILE" > /dev/null
  fi

  # 🧹 Изтриване на todo.modules
  if [ -f "$MODULES_FILE" ]; then
    sudo rm -f "$MODULES_FILE"
    echo "🗑️  Изтрит файл: $MODULES_FILE"
  fi

  # 🧨 Самоизтриване на скрипта
  echo ""
  echo "🎉 Скриптът е отбелязан като ЗАВЪРШЕН в setup.env"
  echo "🧨 Изтриване на текущия скрипт: $0"
  echo ""
  rm -- "$0"

elif [[ "$confirm" == "n" ]]; then
  echo ""
  echo "⚠️ Скриптът не е отбелязан като завършен. Можете да го доработите и стартирате отново."
  echo ""
else
  echo ""
  echo "❌ Невалиден отговор. Моля, стартирайте отново този модул ръчно."
  echo ""
fi

#----------- Край на скрипта -----------

