#!/bin/bash

# ==========================================================================
#  ssh-server-key - Автоматизирано създаване и качване на SSH ключове
# --------------------------------------------------------------------------
#  Версия: 1.0
#  Дата: 2025-05-22
#  Автор: Ilko Yordanov / NetGalaxy
# ==========================================================================
#
#  Този скрипт извършва:
#    ✔ Създаване на SSH ключове (ако не съществуват или при заявено презаписване)
#    ✔ Качване на публичния ключ на отдалечен сървър чрез ssh-copy-id
#    ✔ Добавяне на конфигурация за бърза SSH връзка в ~/.ssh/config
#
#  Етапи:
#    1. Въвеждане на IP адрес, псевдоним и настройки за връзка
#    2. Проверка за съществуващи ключове и опция за презапис
#    3. Генериране на ключове (ако е избрано)
#    4. Качване на публичния ключ на сървъра
#    5. Запис в SSH config за бърза връзка
# ==========================================================================
#
# === ПОМОЩНА ИНФОРМАЦИЯ ===================================================
show_help() {
  echo "Използване: ssh-server-key.sh [опция]"
  echo ""
  echo "Автоматизирано създаване и качване на SSH ключ към отдалечен сървър."
  echo ""
  echo "Опции:"
  echo "  --version       Показва версията на скрипта"
  echo "  --help          Показва тази помощ"
}

# === ОБРАБОТКА НА ОПЦИИ ====================================================
if [[ $# -gt 0 ]]; then
  case "$1" in
    --version)
      echo "ssh-server-key версия 1.0 (22 май 2025 г.)"
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

# === ВИЗУАЛЕН ХЕДЕР ========================================================
echo ""
echo -e "\e[32m=============================================="
echo -e "   СЪЗДАВАНЕ И КАЧВАНЕ НА SSH КЛЮЧОВЕ"
echo -e "==============================================\e[0m"
echo ""
echo ""

###############################################################################
echo "[1] ВЪВЕЖДАНЕ НА ВАЛИДЕН IPv4 АДРЕС..."
echo "-------------------------------------------------------------------------"

# Функция за проверка на валиден IPv4 адрес
is_valid_ip() {
  local ip_input=$1
  [[ $ip_input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r -a octets <<< "$ip_input"
  for octet in "${octets[@]}"; do
    ((octet >= 0 && octet <= 255)) || return 1
  done
  return 0
}

while true; do
  read -rp "Въведете IP адрес на сървъра (или 'q' за изход): " host_ip

  if [[ -z "$host_ip" ]]; then
    echo "❌ Въвеждането на IP адрес е задължително (или 'q' за изход)."
    continue
  fi

  if [[ "$host_ip" == "q" ]]; then
    echo "⛔ Прекъсване от оператора."
    exit 0
  fi

  if ! is_valid_ip "$host_ip"; then
    echo "❌ Невалиден IP адрес. Опитайте отново."
    continue
  fi

  echo "✅ Въведеният IP адрес '$host_ip' е валиден."  # <- Тук
  break
done

echo ""
echo ""


###############################################################################
echo "[2] ВЪВЕЖДАНЕ НА СЪРВЪРЕН ПСЕВДОНИМ..."
echo "-------------------------------------------------------------------------"

# Допустими символи: букви, цифри, тире и долна черта. Дължина: 3 до 15 знака.
while true; do
  read -rp "Въведете сървърен псевдоним (букви, цифри, '-', '_', 3-20 символа): " server_alias
  if [[ "$server_alias" =~ ^[a-zA-Z0-9_-]{3,20}$ ]]; then
    break
  else
    echo "Невалиден псевдоним. Моля, използвайте само букви, цифри, тире и долна черта, между 3 и 20 символа."
  fi
done
echo "✅ Въведеният псевдоним '$server_alias' е валиден."

echo ""
echo ""


###############################################################################
echo "[3] ВЪВЕЖДАНЕ НА ПСЕВДОНИМ ЗА БЪРЗА SSH ВРЪЗКА..."
echo "-------------------------------------------------------------------------"

# Резервирани псевдоними, които не трябва да се използват
reserved_aliases=("root" "default" "admin")

# Функция за валидация на псевдоним
validate_alias() {
  local alias="$1"

  # Проверка за дължина и допустими символи
  if ! [[ "$alias" =~ ^[a-zA-Z0-9_-]{2,10}$ ]]; then
    echo "❌ Невалиден псевдоним. Допускат се само букви, цифри, '-', '_', между 2 и 10 символа."
    return 1
  fi

  # Проверка дали е в списъка със забранени имена
  for reserved in "${reserved_aliases[@]}"; do
    if [[ "$alias" == "$reserved" ]]; then
      echo "❌ Псевдонимът '$alias' е запазен и не може да бъде използван."
      return 2
    fi
  done

  return 0
}

# Четене от потребителя
while true; do
  read -rp "Въведете псевдоним за бърза SSH връзка (напр. myserver или 'q' за изход): " quick_connect

  if [[ -z "$quick_connect" ]]; then
    echo "❌ Въвеждането на псевдоним е задължително. Опитайте отново."
    continue
  fi

  if [[ "$quick_connect" == "q" ]]; then
    echo "⛔ Прекъсване от оператора."
    exit 0
  fi

  if validate_alias "$quick_connect"; then
    break
  fi

  # Функцията вече е изписала грешка, не повтаряме съобщението тук
done

echo "✅ Въведеният псевдоним '$quick_connect' е валиден."
echo ""
echo ""


###############################################################################
echo "[4] ПРОВЕРКА НА SSH ПСЕВДОНИМА..."
echo "-------------------------------------------------------------------------"

overwrite_config="false"

# Проверка дали псевдонимът вече съществува в SSH config файла
if grep -qE "^Host $quick_connect\$" "$config_file" 2>/dev/null; then
  while true; do
    read -rp "Конфигурацията за '$quick_connect' вече съществува. Да бъде ли презаписана? [y/N/q]: " confirm
    case "$confirm" in
      [yY]) 
        echo "✅ Записът ще бъде обновен."
        overwrite_config="true"
        break
        ;;
      [nN]|"") 
        echo "⏭️  Прескачане на запис в config файла."
        break
        ;;
      [qQ]) 
        echo "⛔ Прекратено от оператора."
        exit 0
        ;;
      *) 
        echo "❌ Невалиден отговор. Опитайте отново."
        ;;
    esac
  done
fi

echo "✅ Ще бъде използван псевдоним '$quick_connect'."
echo ""
echo ""


###############################################################################
echo "[5] ПРОВЕРКА ЗА НАЛИЧНИ SSH КЛЮЧОВЕ..."
echo "-------------------------------------------------------------------------"

# Път до SSH ключа – на база сървърен псевдоним
key_path="$HOME/.ssh/${server_alias}"

overwrite_keys=false

# Проверка дали ключовете вече съществуват
if [[ -f "$key_path" || -f "$key_path.pub" ]]; then
  echo "🔑 Открити съществуващи SSH ключове:"
  echo " - $key_path"
  echo " - $key_path.pub"
  echo ""
  while true; do
    read -rp "Желаете ли да презапишете ключовете? [y/N/q]: " overwrite
    case "$overwrite" in
      [yY])
        overwrite_keys=true
        echo "✅ Ключовете ще бъдат презаписани на по-късен етап."
        break
        ;;
      [nN]|"")
        echo "✔️ Съществуващите ключове ще бъдат използвани."
        break
        ;;
      [qQ])
        echo "⛔ Прекратено от оператора."
        exit 0
        ;;
      *) echo "❌ Невалиден отговор. Опитайте отново." ;;
    esac
  done
else
  echo "ℹ️ Не са открити SSH ключове за '$server_alias'. Ще бъдат създадени по-късно."
  overwrite_keys=true
fi

echo ""
echo ""


###############################################################################
echo "[6] ПРОВЕРКА НА СЪБРАНИТЕ ДАННИ..."
echo "-------------------------------------------------------------------------"

echo ""
echo "  🖧 IP адрес на сървъра              : $host_ip"
echo "  🏷️ Сървърен псевдоним               : $server_alias"
echo "  🏷️ Псевдоним за бърза SSH връзка    : $quick_connect"
echo "  🔐 Ключове за SSH достъп           : $HOME/.ssh/${server_alias}"
echo "  ------------------------------------"
if [[ "$overwrite_keys" == true ]]; then
  echo "  ⚠️  Ключовете ще бъдат презаписани."
else
  echo "  ✅ Ще бъдат използвани съществуващите ключове."
fi
echo ""

# Възможност за потвърждение или изход
while true; do
  read -rp "Желаете ли да продължите с конфигурацията? [Enter = продължи / q = изход]: " next_step
  case "$next_step" in
    [qQ])
      echo "⛔ Прекратяване за преглед или корекции."
      exit 0
      ;;
    "")
      echo "✅ Продължаване на конфигурирането..."
      break
      ;;
    *)
      echo "❌ Невалиден отговор. Натиснете Enter за продължение или 'q' за изход."
      ;;
  esac
done

echo ""
echo ""


###############################################################################
echo "[7] СЪЗДАВАНЕ НА SSH КЛЮЧОВЕ (ако е избрано)..."
echo "-------------------------------------------------------------------------"

key_path="$HOME/.ssh/${server_alias}"

if [[ "$overwrite_keys" == true ]]; then
  echo "🔐 Генериране на нов SSH ключ за сървърен псевдоним '$server_alias'..."
  ssh-keygen -t ed25519 -f "$key_path" -C "$USER@${server_alias}" -N ""
  if [[ $? -eq 0 ]]; then
    echo "✅ SSH ключовете са успешно създадени:"
    echo "   - Приватен ключ: $key_path"
    echo "   - Публичен ключ: ${key_path}.pub"
  else
    echo "❌ Грешка при създаване на ключовете!"
    exit 1
  fi
else
  echo "ℹ️ Пропускане на създаване на SSH ключ. Ще се използва съществуващ (ако има):"
  echo "   - $key_path"
fi

echo ""
echo ""


echo "[8] КАЧВАНЕ НА ПУБЛИЧНИЯ КЛЮЧ НА СЪРВЪРА..."
echo "-------------------------------------------------------------------------"

read -rp "Въведете потребителско име за $host_ip: " ssh_user
read -rp "Въведете SSH порт за връзка (натиснете Enter за 22): " ssh_port
ssh_port="${ssh_port:-22}"  # ако няма въведен порт, използваме 22

# Проверка за наличие на необходимите файлове
if [[ ! -f "$key_path" || ! -f "$key_path.pub" ]]; then
  echo "❌ Не са открити SSH ключовете за '$server_alias'. Очаква се: $key_path и ${key_path}.pub"
  echo "   Ако искате да генерирате ключове, рестартирайте скрипта и изберете 'y' при запитването."
  exit 1
fi

echo "🔍 Проверка дали ключът вече е качен..."
if ssh -p "$ssh_port" -o PasswordAuthentication=no -o IdentitiesOnly=yes -i "$key_path" "$ssh_user@$host_ip" true 2>/dev/null; then
  echo "✅ Ключът вече е качен на $host_ip."
else
  echo "⬆️ Качване на публичния ключ чрез ssh-copy-id..."
  echo "(Може да бъдете подканени да въведете парола)"

  if ! ssh-copy-id \
      -p "$ssh_port" \
      -i "$key_path.pub" \
      -o IdentitiesOnly=yes \
      -o IdentityFile="$key_path" \
      "$ssh_user@$host_ip"; then

    echo "⚠️  Грешка при качването. Принудително премахване на стар хост ключ..."
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host_ip" >/dev/null 2>&1
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[$host_ip]:$ssh_port" >/dev/null 2>&1
    sed -i "/$host_ip/d" "$HOME/.ssh/known_hosts" || true

    echo "🔄 Добавяне на актуалния хост ключ в known_hosts..."
    ssh-keyscan -p "$ssh_port" "$host_ip" >> "$HOME/.ssh/known_hosts" 2>/dev/null

    echo "🔁 Повторен опит за качване..."
    if ! ssh-copy-id \
        -p "$ssh_port" \
        -i "$key_path.pub" \
        -o StrictHostKeyChecking=no \
        -o IdentitiesOnly=yes \
        -o IdentityFile="$key_path" \
        "$ssh_user@$host_ip"; then

      echo "❌ Неуспешно качване дори след почистване на known_hosts."
      exit 1
    fi
  fi
  echo "✅ Публичният ключ е качен успешно."
fi

echo ""
echo ""


###############################################################################
echo "[9] ЗАПИС В SSH CONFIG ФАЙЛА..."
echo "-------------------------------------------------------------------------"

# Проверка дали потребителят избра да презапише записа
if grep -qE "^Host $quick_connect\$" "$config_file" 2>/dev/null; then
  if [[ "$overwrite_config" == "true" ]]; then
    echo "🔁 Обновяване на съществуващия запис за '$quick_connect'..."

    # Изтриване на стария запис
    awk -v alias="$quick_connect" '
      BEGIN {skip=0}
      $1=="Host" && $2==alias {skip=1; next}
      skip && $1=="Host" {skip=0}
      !skip {print}
    ' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
  else
    echo "⏭️  Записът в config файла беше пропуснат по избор на оператора."
    echo ""
    echo ""
    exit 0
  fi
fi

# Добавяне на новия запис
{
  echo "Host $quick_connect"
  echo "    HostName $host_ip"
  echo "    User $ssh_user"
  echo "    Port $ssh_port"
  echo "    IdentityFile $key_path"
  echo "    IdentitiesOnly yes"
} >> "$config_file"

chmod 600 "$config_file"

echo "✅ Записът за '$quick_connect' беше добавен в $config_file"
echo "📡 Вече можете да се свързвате със: ssh $quick_connect"
echo ""
echo "❓ Желаете ли да създадете друг SSH ключ?"
echo "[y] - Стартиране на скрипта отначало"
echo "[n] - Благодарим за използването! Скриптът ще бъде премахнат."
echo ""

while true; do
  read -rp "Вашият избор (y/n): " choice
  case "$choice" in
    [Yy])
      echo "🔄 Рестартиране на скрипта..."
      exec "$0"
      ;;
    [Nn])
      echo "🙏 Благодарим, че използвахте ssh-server-key.sh!"
      echo "🧹 Премахване на скрипта..."
      if [[ -f "$0" ]]; then
        rm -- "$0" && echo "✅ Скриптът беше изтрит успешно."
      else
        echo "ℹ️ Скриптът вече е изтрит или липсва."
      fi
      exit 0
      ;;
    *)
      echo "❌ Невалиден избор. Моля, въведете 'y' или 'n'."
      ;;
  esac
done

echo ""
echo ""
# --------- Край на скрипта ---------
