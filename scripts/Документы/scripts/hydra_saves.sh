#!/usr/bin/env bash

set -euo pipefail

HYDRA_DIR="${HYDRA_DIR:-$HOME/.config/hydralauncher}"
PREFIX_ROOT="${PREFIX_ROOT:-$HYDRA_DIR/wine-prefixes}"
HYDRA_DB="${HYDRA_DB:-$HYDRA_DIR/hydra-db}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/game-linux/Hydra-Saves}"
CURRENT_ROOT="$BACKUP_ROOT/current"
LOG_ROOT="$BACKUP_ROOT/logs"
LUDUSAVI_ROOT="$BACKUP_ROOT/ludusavi"
METADATA_FILE="$BACKUP_ROOT/hydra-games.tsv"

SAVE_DIRS=(
  "drive_c/users/steamuser/Documents"
  "drive_c/users/steamuser/Saved Games"
  "drive_c/users/steamuser/AppData/Roaming"
  "drive_c/users/steamuser/AppData/Local"
  "drive_c/users/steamuser/AppData/LocalLow"
  "drive_c/users/Public/Documents"
)

declare -A GAME_TITLES=()

die() {
  printf 'Ошибка: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Использование:
  hydra_saves.sh scan
  hydra_saves.sh backup
  hydra_saves.sh list
  hydra_saves.sh restore <appid|часть-названия|all>
  hydra_saves.sh status

Что делает:
  backup   Синхронизирует каталоги с сохранениями из Hydra Wine-префиксов в /mnt/game-linux/Hydra-Saves/current
  restore  Возвращает сохранения обратно в уже существующий Hydra-префикс
  list     Показывает, для каких игр уже есть архивы
  scan     Показывает найденные Hydra-префиксы
EOF
}

require_commands() {
  local missing=()
  local cmd
  for cmd in rsync strings python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    die "не найдены команды: ${missing[*]}"
  fi
}

ensure_dirs() {
  mkdir -p "$CURRENT_ROOT" "$LOG_ROOT" "$LUDUSAVI_ROOT"
}

slugify() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  value="$(printf '%s' "$value" | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  if [ -z "$value" ]; then
    value="game"
  fi
  printf '%s' "$value"
}

load_game_titles() {
  if [ -f "$METADATA_FILE" ]; then
    while IFS=$'\t' read -r appid title _label _prefix; do
      [ -n "$appid" ] || continue
      case "$appid" in
        \#*) continue ;;
      esac
      GAME_TITLES["$appid"]="$title"
    done < "$METADATA_FILE"
  fi

  if [ ! -d "$HYDRA_DB" ]; then
    return
  fi

  while IFS=$'\t' read -r appid title; do
    [ -n "$appid" ] || continue
    if [ -z "${GAME_TITLES[$appid]:-}" ] || [ "${GAME_TITLES[$appid]}" = "AppID $appid" ]; then
      GAME_TITLES["$appid"]="$title"
    fi
  done < <(
    python3 - "$HYDRA_DB" <<'PY'
import json
import os
import re
import subprocess
import sys

db = sys.argv[1]
files = []
for entry in sorted(os.listdir(db)):
    path = os.path.join(db, entry)
    if os.path.isfile(path):
        files.append(path)

if not files:
    raise SystemExit(0)

proc = subprocess.run(
    ["strings", *files],
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    errors="replace",
    check=False,
)

seen = {}
pattern = re.compile(r"!games!steam:(\d+)\n(\{.*?\})", re.S)
for appid, payload_raw in pattern.findall(proc.stdout):
    if appid in seen:
        continue

    try:
        payload = json.loads(payload_raw)
        title = payload.get("title")
    except Exception:
        title_match = re.search(r'"title":"(.*?)"', payload_raw, re.S)
        if not title_match:
            continue
        title = title_match.group(1).replace("\n", " ").strip()

    if title:
        seen[appid] = title

for appid, title in seen.items():
    print(f"{appid}\t{title}")
PY
  )
}

title_for_appid() {
  local appid="$1"
  printf '%s' "${GAME_TITLES[$appid]:-AppID $appid}"
}

prefix_dirs() {
  find "$PREFIX_ROOT" -mindepth 1 -maxdepth 1 -type d | sort
}

write_metadata() {
  local tmp
  tmp="$(mktemp)"
  printf '# appid\ttitle\tlabel\tprefix\n' > "$tmp"

  while IFS= read -r prefix; do
    local appid title label
    appid="$(basename "$prefix")"
    title="$(title_for_appid "$appid")"
    label="${appid}--$(slugify "$title")"
    printf '%s\t%s\t%s\t%s\n' "$appid" "$title" "$label" "$prefix" >> "$tmp"
  done < <(prefix_dirs)

  mv "$tmp" "$METADATA_FILE"
}

print_prefixes() {
  local found=0
  while IFS= read -r prefix; do
    local appid title
    found=1
    appid="$(basename "$prefix")"
    title="$(title_for_appid "$appid")"
    printf '%s\t%s\t%s\n' "$appid" "$title" "$prefix"
  done < <(prefix_dirs)

  if [ "$found" -eq 0 ]; then
    printf 'Hydra-префиксы не найдены в %s\n' "$PREFIX_ROOT"
  fi
}

backup_prefix() {
  local prefix="$1"
  local appid title label target rel src dest copied=0

  appid="$(basename "$prefix")"
  title="$(title_for_appid "$appid")"
  label="${appid}--$(slugify "$title")"
  target="$CURRENT_ROOT/$label"
  mkdir -p "$target"

  printf '[backup] %s (%s)\n' "$title" "$appid"
  for rel in "${SAVE_DIRS[@]}"; do
    src="$prefix/$rel"
    dest="$target/$rel"
    if [ -d "$src" ]; then
      copied=1
      mkdir -p "$dest"
      rsync -a --delete "$src/" "$dest/"
      printf '  sync %s\n' "$rel"
    fi
  done

  if [ "$copied" -eq 0 ]; then
    printf '  пропуск: не найдено каталогов с сохранениями\n'
  fi
}

backup_cmd() {
  local ts log_file had_prefix=0
  require_commands
  ensure_dirs
  load_game_titles
  write_metadata

  ts="$(date '+%Y-%m-%d_%H-%M-%S')"
  log_file="$LOG_ROOT/backup-$ts.log"
  printf 'Hydra save backup: %s\n' "$ts" | tee "$log_file"
  printf 'Источник: %s\nАрхив: %s\n\n' "$PREFIX_ROOT" "$CURRENT_ROOT" | tee -a "$log_file"

  while IFS= read -r prefix; do
    had_prefix=1
    backup_prefix "$prefix" | tee -a "$log_file"
  done < <(prefix_dirs)

  if [ "$had_prefix" -eq 0 ]; then
    die "Hydra-префиксы не найдены в $PREFIX_ROOT"
  fi

  printf '\nГотово. Логи: %s\n' "$log_file" | tee -a "$log_file"
}

list_backups() {
  local found=0
  if [ ! -d "$CURRENT_ROOT" ]; then
    printf 'Архивов пока нет: %s\n' "$CURRENT_ROOT"
    return
  fi

  while IFS= read -r dir; do
    local label appid title size
    found=1
    label="$(basename "$dir")"
    appid="${label%%--*}"
    title="$(title_for_appid "$appid")"
    size="$(du -sh "$dir" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\n' "$appid" "$title" "$size" "$dir"
  done < <(find "$CURRENT_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)

  if [ "$found" -eq 0 ]; then
    printf 'Архивов пока нет: %s\n' "$CURRENT_ROOT"
  fi
}

restore_one() {
  local dir="$1"
  local label appid title prefix rel src dest restored=0

  label="$(basename "$dir")"
  appid="${label%%--*}"
  title="$(title_for_appid "$appid")"
  prefix="$PREFIX_ROOT/$appid"

  if [ ! -d "$prefix" ]; then
    printf '[restore] пропуск: %s (%s), Hydra-префикс не найден: %s\n' "$title" "$appid" "$prefix"
    return 1
  fi

  printf '[restore] %s (%s)\n' "$title" "$appid"
  for rel in "${SAVE_DIRS[@]}"; do
    src="$dir/$rel"
    dest="$prefix/$rel"
    if [ -d "$src" ]; then
      restored=1
      mkdir -p "$dest"
      rsync -a "$src/" "$dest/"
      printf '  restore %s\n' "$rel"
    fi
  done

  if [ "$restored" -eq 0 ]; then
    printf '  пропуск: в архиве нет данных\n'
  fi
}

resolve_matches() {
  local query="$1"
  local query_lc label appid title title_lc
  query_lc="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"

  while IFS= read -r dir; do
    label="$(basename "$dir")"
    appid="${label%%--*}"
    title="$(title_for_appid "$appid")"
    title_lc="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')"

    if [ "$query" = "$appid" ] || [ "$query" = "$label" ]; then
      printf '%s\n' "$dir"
      continue
    fi

    case "$title_lc" in
      *"$query_lc"*) printf '%s\n' "$dir" ;;
    esac
  done < <(find "$CURRENT_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
}

restore_cmd() {
  local query="${1:-}"
  local matches=()
  local dir

  [ -n "$query" ] || die "укажи appid, часть названия игры или all"
  require_commands
  ensure_dirs
  load_game_titles

  if [ ! -d "$CURRENT_ROOT" ]; then
    die "архивы не найдены: $CURRENT_ROOT"
  fi

  if [ "$query" = "all" ]; then
    while IFS= read -r dir; do
      matches+=("$dir")
    done < <(find "$CURRENT_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
  else
    while IFS= read -r dir; do
      matches+=("$dir")
    done < <(resolve_matches "$query")
  fi

  if [ "${#matches[@]}" -eq 0 ]; then
    die "совпадений для '$query' не найдено"
  fi

  if [ "$query" != "all" ] && [ "${#matches[@]}" -gt 1 ]; then
    printf 'Найдено несколько совпадений для "%s":\n' "$query" >&2
    for dir in "${matches[@]}"; do
      local label appid title
      label="$(basename "$dir")"
      appid="${label%%--*}"
      title="$(title_for_appid "$appid")"
      printf '  %s\t%s\n' "$appid" "$title" >&2
    done
    exit 1
  fi

  for dir in "${matches[@]}"; do
    restore_one "$dir"
  done
}

status_cmd() {
  local prefixes backups
  prefixes="$(find "$PREFIX_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  backups="$(find "$CURRENT_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || true)"

  printf 'Hydra dir:      %s\n' "$HYDRA_DIR"
  printf 'Prefix root:    %s\n' "$PREFIX_ROOT"
  printf 'Backup root:    %s\n' "$BACKUP_ROOT"
  printf 'Current saves:  %s\n' "$CURRENT_ROOT"
  printf 'Ludusavi root:  %s\n' "$LUDUSAVI_ROOT"
  printf 'Prefixes found: %s\n' "$prefixes"
  printf 'Backups found:  %s\n' "$backups"
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    scan)
      require_commands
      ensure_dirs
      load_game_titles
      write_metadata
      print_prefixes
      ;;
    backup)
      backup_cmd
      ;;
    list)
      require_commands
      ensure_dirs
      load_game_titles
      list_backups
      ;;
    restore)
      shift || true
      restore_cmd "${1:-}"
      ;;
    status)
      status_cmd
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
