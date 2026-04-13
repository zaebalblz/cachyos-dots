#!/usr/bin/env bash

set -euo pipefail

game_dir='/mnt/game-linux/hydra-game/Good.Pizza.Great.Pizza.5.29.2/Good Pizza, Great Pizza'
game_exe="$game_dir/PizzaBusiness.exe"
wineprefix="$HOME/.config/hydralauncher/wine-prefixes/770810"
umu_run='/opt/Hydra/resources/umu-run'
python_bin='/usr/bin/python3'

if ! command -v unshare >/dev/null 2>&1; then
  printf 'Missing required command: unshare\n' >&2
  exit 1
fi

for required_path in "$game_exe" "$wineprefix" "$umu_run" "$python_bin"; do
  if [[ ! -e "$required_path" ]]; then
    printf 'Missing required path: %s\n' "$required_path" >&2
    exit 1
  fi
done

cd "$game_dir"

export PROTON_LOG=1
export GAMEID='umu-770810'
export WINEPREFIX="$wineprefix"

exec unshare --user --map-root-user --net "$python_bin" "$umu_run" "$game_exe"
