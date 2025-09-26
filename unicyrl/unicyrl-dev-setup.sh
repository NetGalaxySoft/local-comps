#!/usr/bin/env bash
# ==========================================================================
#  unicyrl-dev-setup.sh – Инсталатор на XKB подредба "UniCyrl"
# --------------------------------------------------------------------------
#  Версия: 2.2 (no-force-apply)
#  Дата: 2025-09-26
#  Автор: Ilko Yordanov / NetGalaxySoft
# ==========================================================================
#  Какво прави:
#    - Записва символен файл /usr/share/X11/xkb/symbols/uc
#    - Регистрира нов layout "uc" в /usr/share/X11/xkb/rules/evdev.xml
#    - НЕ сменя активната подредба на потребителя
#    - Поддържа деинсталация с --uninstall
# ==========================================================================

set -euo pipefail

XKB_DIR="/usr/share/X11/xkb"
SYM_DIR="$XKB_DIR/symbols"
RULES_XML="$XKB_DIR/rules/evdev.xml"

LAYOUT_NAME="uc"          # ще се появи като отделен layout
BACKUP_DIR="/etc/netgalaxy/unicyrl-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log(){ printf '%s\n' "$*"; }
ok(){  printf '✅ %s\n' "$*"; }
err(){ printf '❌ %s\n' "$*" >&2; }

require_root(){
  if [[ $EUID -ne 0 ]]; then
    err "Моля, стартирай със sudo."
    exit 1
  fi
}

backup_file(){
  local src="$1" dst_dir="$2"
  mkdir -p "$dst_dir"
  if [[ -f "$src" ]]; then
    cp -a "$src" "$dst_dir/$(basename "$src").$TIMESTAMP.bak"
  fi
}

# НЕ сменяме подредбата! Само чистим кеша, за да се прочете новият layout
refresh_cache(){
  rm -rf /var/lib/xkb/* 2>/dev/null || true
  # Никакъв setxkbmap тук.
}

evdev_has_layout(){
  grep -q "<name>$LAYOUT_NAME</name>" "$RULES_XML"
}

install_symbols(){
  require_root
  mkdir -p "$SYM_DIR"
  local target="$SYM_DIR/$LAYOUT_NAME"
  [[ -f "$target" ]] && backup_file "$target" "$BACKUP_DIR"

  cat > "$target" <<'EOF'
default  partial alphanumeric_keys
xkb_symbols "basic" {
    // Базирано на стандартната българска фонетична
    include "bg(phonetic)"
    name[Group1]= "UniCyrl (phonetic; BG remaps v2)";

    // ` -> ь, Shift+` -> Ь; на 3-то/4-то ниво остават ASCII (` и ~)
    key <TLDE> { [ Cyrillic_softsign, Cyrillic_SOFTSIGN, grave, asciitilde ] };

    // w -> ж
    key <AD02> { [ Cyrillic_zhe,      Cyrillic_ZHE      ] };

    // v -> в
    key <AB04> { [ Cyrillic_ve,       Cyrillic_VE       ] };

    // x -> ч
    key <AB02> { [ Cyrillic_che,      Cyrillic_CHE      ] };

    // ; и : остават ASCII
    key <AC10> { [ semicolon, colon ] };

    // Shift+, -> < ; Shift+. -> >
    key <AB08> { [ comma,  less ] };
    key <AB09> { [ period, greater ] };

    // подсигуряване на [ ] и \ (ш, щ, ю)
    key <AD11> { [ Cyrillic_sha,      Cyrillic_SHA      ] };
    key <AD12> { [ Cyrillic_shcha,    Cyrillic_SHCHA    ] };
    key <BKSL> { [ Cyrillic_yu,       Cyrillic_YU       ] };
};
EOF

  chmod 0644 "$target"
  ok "Символен файл записан: $target"
}

install_rules(){
  require_root
  backup_file "$RULES_XML" "$BACKUP_DIR"

  if evdev_has_layout; then
    ok "Layout \"$LAYOUT_NAME\" вече е регистриран (evdev.xml)"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v L="$LAYOUT_NAME" '
    /<\/layoutList>/ && !done {
      print "    <layout>";
      print "      <configItem>";
      print "        <name>" L "</name>";
      print "        <shortDescription>UC</shortDescription>";
      print "        <description>UC (phonetic)</description>";
      print "        <languageList>";
      print "          <iso639Id>bul</iso639Id>";
      print "        </languageList>";
      print "      </configItem>";
      print "    </layout>";
      done=1
    }
    { print }
  ' "$RULES_XML" > "$tmp"

  mv "$tmp" "$RULES_XML"
  chmod 0644 "$RULES_XML"
  ok "Добавен layout в evdev.xml (ще се вижда за избор в KDE/GNOME)"
}

uninstall(){
  require_root
  log "Деинсталация…"

  if evdev_has_layout; then
    backup_file "$RULES_XML" "$BACKUP_DIR"
    local tmp; tmp="$(mktemp)"
    awk -v L="$LAYOUT_NAME" '
      BEGIN{inlayout=0; buf=""}
      /<layout>/ {buf=$0; inlayout=1; next}
      inlayout && /<\/layout>/ {
        buf=buf ORS $0
        if (buf ~ "<name>" L "</name>") {
          # пропускаме този блок (т.е. изтриваме layout-а)
        } else {
          print buf
        }
        inlayout=0; buf=""; next
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
  ok "Кешът е обновен. Нищо не е сменяно по текущата подредба."
}

install(){
  require_root
  log "Инсталация на UniCyrl XKB…"
  install_symbols
  install_rules
  refresh_cache

  cat <<'MSG'

========================================
✅ Инсталирано (без да се сменя текущата подредба).

Добавяне от интерфейса:
  System Settings → Input Devices → Keyboard → Layouts
    → Add → UC (phonetic) → Apply

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
