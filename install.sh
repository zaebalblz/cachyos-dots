#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"
BACKUP_ROOT=""
DO_BACKUP=1
INSTALL_PACKAGES=1
APPLY_CONFIGS=1
WITH_AUR=1
FULL_PROFILE=1
INCLUDE_OPTIONAL_STOW=1

CORE_STOW_PACKAGES=(
  btop
  fastfetch
  fish
  foot
  hypr
  kitty
  noctalia
  scripts
  waybar
)

OPTIONAL_STOW_PACKAGES=(
  Wallpapers
  steam
)

CORE_SYSTEM_PACKAGES=(
  git
  stow
  findutils
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
  cava
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
  quickshell
  noctalia-qs
  adw-gtk-theme
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
)

FULL_SYSTEM_PACKAGES=(
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
  bibata-cursor-theme-bin
  portproton
  pipes.sh
)

usage() {
  cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --minimal
  ./install.sh --packages-only
  ./install.sh --configs-only
  ./install.sh hypr kitty fish
  ./install.sh --target /tmp/test-home --configs-only --no-backup
  ./install.sh --list

By default this script performs a full Arch/CachyOS install:
  - installs system packages via pacman
  - installs AUR/helper packages via yay or paru if available
  - applies all stow packages, including Wallpapers and steam

Options:
  --all                explicit full profile (default)
  --minimal            install only the core desktop stack and core stow packages
  --packages-only      install packages only, skip GNU Stow
  --configs-only       apply GNU Stow packages only, skip pacman/AUR
  --no-aur             skip yay/paru packages
  --no-backup          do not move conflicting files before stow
  --target DIR         install stow links into DIR instead of $HOME
  --list               print package groups and available stow packages
  -h, --help           show this help

Positional arguments are treated as specific stow packages to apply.
EOF
}

log() {
  printf '[install] %s\n' "$*"
}

warn() {
  printf '[install] Warning: %s\n' "$*" >&2
}

die() {
  printf '[install] Error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
    return
  fi

  require_cmd sudo
  sudo "$@"
}

print_list() {
  printf 'Core stow packages:\n'
  printf '  %s\n' "${CORE_STOW_PACKAGES[@]}"
  printf 'Optional stow packages:\n'
  printf '  %s\n' "${OPTIONAL_STOW_PACKAGES[@]}"
  printf 'Core system packages:\n'
  printf '  %s\n' "${CORE_SYSTEM_PACKAGES[@]}"
  printf 'Full-profile extra packages:\n'
  printf '  %s\n' "${FULL_SYSTEM_PACKAGES[@]}"
  printf 'AUR/helper packages:\n'
  printf '  %s\n' "${AUR_PACKAGES[@]}"
}

append_unique() {
  local value="$1"
  local item

  for item in "${RESULT[@]:-}"; do
    [[ "$item" == "$value" ]] && return 0
  done

  RESULT+=("$value")
}

package_in_syncdb() {
  pacman -Si "$1" >/dev/null 2>&1
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

is_known_stow_package() {
  local wanted="$1"
  local pkg

  for pkg in "${CORE_STOW_PACKAGES[@]}" "${OPTIONAL_STOW_PACKAGES[@]}"; do
    [[ "$pkg" == "$wanted" ]] && return 0
  done

  return 1
}

resolve_stow_packages() {
  local pkg

  STOW_PACKAGES_TO_APPLY=()

  if [[ "${#STOW_PACKAGES[@]}" -gt 0 ]]; then
    for pkg in "${STOW_PACKAGES[@]}"; do
      is_known_stow_package "$pkg" || die "Unknown stow package: $pkg"
      [[ -d "${REPO_DIR}/${pkg}" ]] || die "Package directory not found: ${pkg}"
      STOW_PACKAGES_TO_APPLY+=("$pkg")
    done
    return
  fi

  STOW_PACKAGES_TO_APPLY=("${CORE_STOW_PACKAGES[@]}")
  if [[ "${INCLUDE_OPTIONAL_STOW}" -eq 1 ]]; then
    STOW_PACKAGES_TO_APPLY+=("${OPTIONAL_STOW_PACKAGES[@]}")
  fi
}

build_package_lists() {
  local pkg

  RESULT=()
  PACMAN_TARGETS=()
  HELPER_TARGETS=()
  UNRESOLVED_PACKAGES=()

  for pkg in "${CORE_SYSTEM_PACKAGES[@]}"; do
    append_unique "$pkg"
  done

  if [[ "${FULL_PROFILE}" -eq 1 ]]; then
    for pkg in "${FULL_SYSTEM_PACKAGES[@]}"; do
      append_unique "$pkg"
    done
  fi

  for pkg in "${RESULT[@]}"; do
    if package_in_syncdb "$pkg"; then
      PACMAN_TARGETS+=("$pkg")
    else
      UNRESOLVED_PACKAGES+=("$pkg")
    fi
  done

  if [[ "${WITH_AUR}" -eq 1 ]]; then
    for pkg in "${UNRESOLVED_PACKAGES[@]}"; do
      HELPER_TARGETS+=("$pkg")
    done
    for pkg in "${AUR_PACKAGES[@]}"; do
      HELPER_TARGETS+=("$pkg")
    done
  fi
}

prepare_target_dirs() {
  mkdir -p -- "${TARGET_DIR}"
  mkdir -p -- "${TARGET_DIR}/Изображения/Снимки экрана"
  mkdir -p -- "${TARGET_DIR}/Документы/appimage"
  mkdir -p -- "${TARGET_DIR}/.local/bin"
  mkdir -p -- "${TARGET_DIR}/.local/share"
}

run_pacman_install() {
  [[ "${#PACMAN_TARGETS[@]}" -gt 0 ]] || return 0
  log "Installing pacman packages"
  run_as_root pacman -S --needed "${PACMAN_TARGETS[@]}"
}

run_helper_install() {
  local helper="$1"

  [[ "${#HELPER_TARGETS[@]}" -gt 0 ]] || return 0

  log "Installing helper/AUR packages via ${helper}"
  "${helper}" -S --needed "${HELPER_TARGETS[@]}"
}

should_ignore_relpath() {
  local relpath="$1"
  case "$relpath" in
    */__pycache__/*|__pycache__/*|*.pyc|*.pyo|*.swp|*.bak|*/fish_variables|fish_variables)
      return 0
      ;;
  esac
  return 1
}

ensure_backup_root() {
  if [[ "${DO_BACKUP}" -eq 1 && -z "${BACKUP_ROOT}" ]]; then
    BACKUP_ROOT="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p -- "${BACKUP_ROOT}"
  fi
}

backup_path() {
  local source_path="$1"
  local relpath="$2"
  local backup_path=""

  if [[ "${DO_BACKUP}" -ne 1 ]]; then
    return 0
  fi

  ensure_backup_root

  backup_path="${BACKUP_ROOT}/${relpath}"
  mkdir -p -- "$(dirname -- "${backup_path}")"
  mv -- "${source_path}" "${backup_path}"
  printf 'Backed up %s -> %s\n' "${source_path}" "${backup_path}"
}

backup_parent_conflicts() {
  local relpath="$1"
  local parent_rel=""
  local built=""
  local part=""
  local target_path=""

  parent_rel="$(dirname -- "${relpath}")"
  [[ "${parent_rel}" == "." ]] && return 0

  IFS='/' read -r -a parts <<< "${parent_rel}"
  for part in "${parts[@]}"; do
    [[ -z "${part}" ]] && continue

    if [[ -z "${built}" ]]; then
      built="${part}"
    else
      built="${built}/${part}"
    fi

    target_path="${TARGET_DIR}/${built}"
    if [[ ( -e "${target_path}" || -L "${target_path}" ) && ! -d "${target_path}" ]]; then
      backup_path "${target_path}" "${built}"
    fi
  done
}

backup_conflicts_for_package() {
  local package="$1"
  local package_dir="${REPO_DIR}/${package}"
  local source_path=""
  local relpath=""
  local target_path=""
  local current_target=""
  local desired_target=""

  while IFS= read -r -d '' source_path; do
    relpath="${source_path#${package_dir}/}"
    target_path="${TARGET_DIR}/${relpath}"
    current_target=""
    desired_target=""

    should_ignore_relpath "${relpath}" && continue
    backup_parent_conflicts "${relpath}"

    if [[ -L "${target_path}" ]]; then
      current_target="$(readlink -f -- "${target_path}" || true)"
      desired_target="$(readlink -f -- "${source_path}")"
      [[ "${current_target}" == "${desired_target}" ]] && continue
    fi

    if [[ -e "${target_path}" || -L "${target_path}" ]]; then
      backup_path "${target_path}" "${relpath}"
    fi
  done < <(find "${package_dir}" -mindepth 1 ! -type d -print0)
}

apply_stow_packages() {
  local pkg
  local stow_args=()

  require_cmd stow
  require_cmd find

  log "Applying GNU Stow packages into ${TARGET_DIR}"
  printf '  %s\n' "${STOW_PACKAGES_TO_APPLY[@]}"

  if [[ "${DO_BACKUP}" -eq 1 ]]; then
    for pkg in "${STOW_PACKAGES_TO_APPLY[@]}"; do
      backup_conflicts_for_package "${pkg}"
    done
  fi

  stow_args=(
    "--dir=${REPO_DIR}"
    "--target=${TARGET_DIR}"
    "--restow"
    "--ignore=(^|/)__pycache__(/|$)"
    "--ignore=\\.pyc$"
    "--ignore=\\.pyo$"
    "--ignore=\\.swp$"
    "--ignore=\\.bak$"
    "--ignore=(^|/)fish_variables$"
  )

  stow "${stow_args[@]}" "${STOW_PACKAGES_TO_APPLY[@]}"

  if [[ -n "${BACKUP_ROOT}" ]]; then
    log "Conflicting files were backed up to ${BACKUP_ROOT}"
  fi
}

parse_args() {
  STOW_PACKAGES=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        FULL_PROFILE=1
        INCLUDE_OPTIONAL_STOW=1
        ;;
      --minimal)
        FULL_PROFILE=0
        INCLUDE_OPTIONAL_STOW=0
        ;;
      --packages-only)
        APPLY_CONFIGS=0
        ;;
      --configs-only)
        INSTALL_PACKAGES=0
        ;;
      --no-aur)
        WITH_AUR=0
        ;;
      --no-backup)
        DO_BACKUP=0
        ;;
      --target)
        shift
        [[ $# -gt 0 ]] || die "--target requires a directory"
        TARGET_DIR="$1"
        ;;
      --list)
        print_list
        exit 0
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        STOW_PACKAGES+=("$1")
        ;;
    esac
    shift
  done
}

main() {
  local helper=""

  parse_args "$@"
  resolve_stow_packages

  if [[ "${INSTALL_PACKAGES}" -eq 1 ]]; then
    require_cmd pacman
    build_package_lists

    if [[ "${WITH_AUR}" -eq 1 ]]; then
      helper="$(detect_aur_helper || true)"
      if [[ -z "${helper}" && "${#HELPER_TARGETS[@]}" -gt 0 ]]; then
        warn "No yay/paru found. These packages will be skipped: ${HELPER_TARGETS[*]}"
        HELPER_TARGETS=()
      fi
    else
      if [[ "${#UNRESOLVED_PACKAGES[@]}" -gt 0 ]]; then
        warn "Skipped packages not found in pacman sync DB because --no-aur was used: ${UNRESOLVED_PACKAGES[*]}"
      fi
      HELPER_TARGETS=()
    fi

    run_pacman_install

    if [[ -n "${helper}" ]]; then
      run_helper_install "${helper}"
    fi
  fi

  prepare_target_dirs

  if [[ "${APPLY_CONFIGS}" -eq 1 ]]; then
    apply_stow_packages
  fi

  warn "AppImage files are not downloaded automatically: ~/Документы/appimage/YouTube-Music.AppImage and ~/Документы/appimage/osu.AppImage"
  warn "The config references icon theme kora-grey in scripts/Документы/scripts/preformencehypr.py; install it manually if you rely on that theme."
  log "Done."
}

main "$@"
