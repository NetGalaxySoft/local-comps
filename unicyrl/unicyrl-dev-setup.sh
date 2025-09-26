#!/usr/bin/env bash
# ==========================================================================
#  unicyrl-dev-setup.sh – Инсталатор на XKB подредба "UniCyrl"
# --------------------------------------------------------------------------
#  Версия: 2.1 (без руски букви) – FIX: символният файл не се пише безусловно;
#                                  FIX: uninstall използва LAYOUT_NAME
#  Дата: 2025-09-26
#  Автор: Ilko Yordanov / NetGalaxySoft
# ==========================================================================
#
#  Цел:
#    - Създава XKB подредба "unicyrl" (variant "phonetic"), базирана на
#      "Bulgarian (phonetic)".
#    - Няма допълнителни промени или руски букви.
#    - Регистрира подредбата в evdev.xml, за да се вижда и избира през KDE.
#    - Позволява деинсталация с параметъра --uninstall.
#
#  Използване:
#    sudo bash unicyrl-dev-setup.sh              # инсталиране
#    sudo bash unicyrl-dev-setup.sh --uninstall  # премахване
#
# ==========================================================================

set -euo pipefail

XKB_DIR="/usr/share/X11/xkb"
SYM_DIR="$XKB_DIR/symbols"
RULES_XML="$XKB_DIR/rules/evdev.xml"
LAYOUT_NAME="unicyrl"
VARIANT_NAME="phonetic"
BACKUP_DIR="/etc/netgalaxy/unicyrl-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log(){ printf '%s\n' "$*"; }
ok(){  printf '✅ %s\n' "$*"; }
err(){ printf '❌ %s\n' "$*" >&2; }

require_root(){
  if [[ $EUID -ne 0 ]]; then
    err "Стартирай със sudo."
    exit 1
  fi
}

backup_file(){
  local src="$1"
  local dst_dir="$2"
  mkdir -p "$dst_dir"
  if [[ -f "$src" ]]; then
    cp -a "$src" "$dst_dir/$(basename "$src").$TIMESTAMP.bak"
  fi
}

refresh_cache(){
  # Изчистване на кеша и опит за прилагане при активния потребител
  rm -rf /var/lib/xkb/* 2>/dev/null || true
  set +e
  sudo -u "$(logname 2>/dev/null || whoami)" sh -lc "setxkbmap $LAYOUT_NAME $VARIANT_NAME" >/dev/null 2>&1 || true
  set -e
}

evdev_has_layout(){
  grep -q "<name>$LAYOUT_NAME</name>" "$RULES_XML"
}

install_symbols(){
  require_root
  mkdir -p "$SYM_DIR"
  local target="$SYM_DIR/$LAYOUT_NAME"
  if [[ -f "$target" ]]; then
    backup_file "$target" "$BACKUP_DIR"
  fi

  cat > "$target" <<'EOF'
default  partial alphanumeric_keys
xkb_symbols "phonetic" {
    // Базирано на стандартната българска фонетична
    include "bg(phonetic)"
    name[Group1]= "UniCyrl (phonetic; BG remaps v1)";

    // --- BG корекции (без руски) ---

    // w -> ж
    key <AD02> { [ Cyrillic_zhe,      Cyrillic_ZHE      ] };

    // v -> в
    key <AB04> { [ Cyrillic_ve,       Cyrillic_VE       ] };

    // x -> ч
    key <AB02> { [ Cyrillic_che,      Cyrillic_CHE      ] };

    // ; -> ь
    key <AC10> { [ Cyrillic_softsign, colon, ellipsis, ellipsis ] };

    // ` и ~ да си останат ASCII
    key <TLDE> { [ grave, asciitilde ] };

    // подсигуряване на [ ] и \ (ш, щ, ю)
    key <AD11> { [ Cyrillic_sha,      Cyrillic_SHA      ] };
    key <AD12> { [ Cyrillic_shcha,    Cyrillic_SHCHA    ] };
    key <BKSL> { [ Cyrillic_yu,       Cyrillic_YU       ] };
};
EOF

  chmod 644 "$target"
  ok "Записан символен файл: $target"
}

install_rules(){
  require_root
  backup_file "$RULES_XML" "$BACKUP_DIR"

  if evdev_has_layout; then
    ok "Layout \"$LAYOUT_NAME\" вече е регистриран в evdev.xml"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v L="$LAYOUT_NAME" -v V="$VARIANT_NAME" '
    /<\/layoutList>/ && !done {
      print "    <layout>";
      print "      <configItem>";
      print "        <name>" L "</name>";
      print "        <shortDescription>uni</shortDescription>";
      print "        <description>UniCyrl (phonetic)</description>";
      print "        <languageList>";
      print "          <iso639Id>bul</iso639Id>";
      print "        </languageList>";
      print "      </configItem>";
      print "      <variantList>";
      print "        <variant>";
      print "          <configItem>";
      print "            <name>" V "</name>";
      print "            <description>UniCyrl phonetic</description>";
      print "          </configItem>";
      print "        </variant>";
      print "      </variantList>";
      print "    </layout>";
      done=1
    }
    { print }
  ' "$RULES_XML" > "$tmp"

  mv "$tmp" "$RULES_XML"
  chmod 644 "$RULES_XML"
  ok "Добавен layout в evdev.xml (видим в интерфейса)"
}

uninstall(){
  require_root
  log "Деинсталация…"

  if evdev_has_layout; then
    backup_file "$RULES_XML" "$BACKUP_DIR"
    local tmp
    tmp="$(mktemp)"
    awk -v L="$LAYOUT_NAME" '
      BEGIN{inlayout=0; buf=""}
      /<layout>/ {buf=$0; inlayout=1; next}
      inlayout && /<\/layout>/ {
        buf=buf ORS $0
        if (buf ~ "<name>" L "</name>") {
          # пропускаме този layout (не го печатаме)
        } else {
          print buf
        }
        inlayout=0
        buf=""
        next
      }
      inlayout { buf=buf ORS $0; next }
      { print }
    ' "$RULES_XML" > "$tmp"
    mv "$tmp" "$RULES_XML"
    ok "Премахнат layout \"$LAYOUT_NAME\" от evdev.xml"
  fi

  local target="$SYM_DIR/$LAYOUT_NAME"
  if [[ -f "$target" ]]; then
    backup_file "$target" "$BACKUP_DIR"
    rm -f "$target"
    ok "Премахнат файл: $target"
  fi

  refresh_cache
  ok "Кешът е обновен."
  log "Готово. Върни се на стандартна подредба от Settings или с: setxkbmap us"
}

install(){
  require_root
  log "Инсталация на UniCyrl XKB…"
  install_symbols
  install_rules
  refresh_cache

  cat <<MSG

========================================
✅ Инсталирано!

Сега отвори:
  System Settings → Input Devices → Keyboard → Layouts
    → Add → UniCyrl (phonetic)
    → Apply

Деинсталация:
  sudo bash unicyrl-dev-setup.sh --uninstall
========================================
MSG
}

main(){
  case "${1:-}" in
    --uninstall) uninstall ;;
    ""|*)        install ;;
  esac
}

main "$@"
