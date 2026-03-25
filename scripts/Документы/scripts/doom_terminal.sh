#!/usr/bin/env bash

set -euo pipefail

local_fixed_dir="$HOME/.local/opt/doom-ascii-fixed"
local_fixed_bin="$local_fixed_dir/doom_ascii.bin"
doom_ascii_bin=""
doom_ascii_home=""

if [[ -x "$local_fixed_bin" ]]; then
  doom_ascii_bin="$local_fixed_bin"
  doom_ascii_home="$local_fixed_dir"
elif command -v doom_ascii >/dev/null 2>&1; then
  doom_ascii_bin="$(command -v doom_ascii)"
else
  echo "Не найден doom_ascii." >&2
  echo "Нужен либо системный пакет, либо локальный бинарь в $local_fixed_bin" >&2
  exit 1
fi

scaling="${DOOM_TERM_SCALING:-4}"
chars="${DOOM_TERM_CHARS:-block}"

search_roots=(
  "$HOME/Games"
  "$HOME/.local/share/Steam/steamapps/common"
  "$HOME/.steam/steam/steamapps/common"
  "/mnt/game-linux/SteamLibrary/steamapps/common"
)

original_names=(
  "DOOM1.WAD"
  "doom1.wad"
  "DOOM.WAD"
  "doom.wad"
  "DOOMU.WAD"
  "doomu.wad"
)

wad_path=""
fallback_wad="$HOME/Games/doom-ascii/freedoom-0.13.0/freedoom1.wad"

if [[ -n "${DOOM_WAD:-}" && -f "${DOOM_WAD}" ]]; then
  wad_path="${DOOM_WAD}"
else
  for root in "${search_roots[@]}"; do
    [[ -d "$root" ]] || continue
    for name in "${original_names[@]}"; do
      match="$(find "$root" -maxdepth 6 -type f -name "$name" -print -quit 2>/dev/null || true)"
      if [[ -n "$match" ]]; then
        wad_path="$match"
        break 2
      fi
    done
  done
fi

if [[ -z "$wad_path" ]]; then
  if [[ -f "$fallback_wad" ]]; then
    wad_path="$fallback_wad"
    echo "Оригинальный WAD не найден, запускаю через Freedoom: $wad_path"
  else
    echo "Не найден ни оригинальный DOOM WAD, ни fallback Freedoom WAD." >&2
    echo "Можно указать свой WAD так: DOOM_WAD=/реальный/путь/к/DOOM.WAD doom_terminal.sh" >&2
    exit 1
  fi
else
  echo "Запускаю DOOM в терминале с WAD: $wad_path"
fi

if [[ -n "$doom_ascii_home" ]]; then
  mkdir -p "$doom_ascii_home/.savegame"
  cd "$doom_ascii_home"
fi

exec "$doom_ascii_bin" -iwad "$wad_path" -chars "$chars" -scaling "$scaling" "$@"
