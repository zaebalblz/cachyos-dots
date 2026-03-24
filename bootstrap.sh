#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WITH_AUR=1
WITH_CONFIGS=1
FULL_PROFILE=1

PACMAN_PACKAGES=(
  git
  stow
  python
  fish
  eza
  direnv
  zoxide
  fastfetch
  btop
  foot
  kitty
  yazi
  code
  firefox
  nautilus
  pavucontrol
  qps
  cmatrix
  tty-clock
  hyprland
  hypridle
  hyprlock
  hyprpaper
  hyprpicker
  hyprshot
  waybar
  wl-clipboard
  cliphist
  libnotify
  bluez-utils
  wireplumber
  wtype
  playerctl
  brightnessctl
  gnome-keyring
  polkit-gnome
  geoclue
  gammastep
  trash-cli
  noctalia-qs
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
)

FULL_PACKAGES=(
  telegram-desktop
  discord
  steam
  prismlauncher
  obs-studio
  godot
  lutris-git
  nemo
)

AUR_PACKAGES=(
  portproton
  pipes.sh
)

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh
  ./bootstrap.sh --minimal
  ./bootstrap.sh --no-aur
  ./bootstrap.sh --packages-only

Options:
  --minimal       install only the desktop/core stack without gaming and extra apps
  --no-aur        skip AUR/helper packages
  --packages-only install packages only, do not run install.sh
  -h, --help      show this help
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*"
}

warn() {
  printf '[bootstrap] Warning: %s\n' "$*" >&2
}

die() {
  printf '[bootstrap] Error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

detect_aur_helper() {
  if command -v yay >/dev/null 2>&1; then
    printf 'yay'
    return 0
  fi

  if command -v paru >/dev/null 2>&1; then
    printf 'paru'
    return 0
  fi

  return 1
}

package_in_syncdb() {
  pacman -Si "$1" >/dev/null 2>&1
}

append_unique() {
  local value="$1"
  local item

  for item in "${RESULT[@]:-}"; do
    [[ "$item" == "$value" ]] && return 0
  done

  RESULT+=("$value")
}

build_package_lists() {
  local pkg
  RESULT=()
  PACMAN_TARGETS=()
  HELPER_TARGETS=()

  for pkg in "${PACMAN_PACKAGES[@]}"; do
    append_unique "$pkg"
  done

  if [[ "$FULL_PROFILE" -eq 1 ]]; then
    for pkg in "${FULL_PACKAGES[@]}"; do
      append_unique "$pkg"
    done
  fi

  for pkg in "${RESULT[@]}"; do
    if package_in_syncdb "$pkg"; then
      PACMAN_TARGETS+=("$pkg")
    else
      HELPER_TARGETS+=("$pkg")
    fi
  done

  if [[ "$WITH_AUR" -eq 1 ]]; then
    for pkg in "${AUR_PACKAGES[@]}"; do
      append_unique "$pkg"
    done
  fi

  if [[ "$WITH_AUR" -eq 1 ]]; then
    for pkg in "${AUR_PACKAGES[@]}"; do
      HELPER_TARGETS+=("$pkg")
    done
  fi
}

run_pacman_install() {
  [[ "${#PACMAN_TARGETS[@]}" -gt 0 ]] || return 0
  log "Installing repo packages via pacman"
  sudo pacman -S --needed "${PACMAN_TARGETS[@]}"
}

run_helper_install() {
  local helper="$1"
  [[ "${#HELPER_TARGETS[@]}" -gt 0 ]] || return 0

  log "Installing helper/AUR packages via ${helper}"
  "$helper" -S --needed "${HELPER_TARGETS[@]}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --minimal)
        FULL_PROFILE=0
        ;;
      --no-aur)
        WITH_AUR=0
        ;;
      --packages-only)
        WITH_CONFIGS=0
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

main() {
  local helper=""

  parse_args "$@"

  require_cmd pacman
  require_cmd sudo

  build_package_lists

  if [[ "$WITH_AUR" -eq 1 ]]; then
    helper="$(detect_aur_helper || true)"
    if [[ -z "$helper" && "${#HELPER_TARGETS[@]}" -gt 0 ]]; then
      warn "No yay/paru found. These packages will be skipped: ${HELPER_TARGETS[*]}"
      HELPER_TARGETS=()
    fi
  else
    HELPER_TARGETS=()
  fi

  run_pacman_install

  if [[ -n "$helper" ]]; then
    run_helper_install "$helper"
  fi

  mkdir -p -- "$HOME/Изображения/Снимки экрана"
  mkdir -p -- "$HOME/Документы/appimage"

  if [[ "$WITH_CONFIGS" -eq 1 ]]; then
    log "Applying dotfiles with GNU Stow"
    bash "$REPO_DIR/install.sh" --all
  fi

  log "Done."
  warn "AppImage paths such as YouTube Music and osu are not auto-downloaded by this script."
}

main "$@"
