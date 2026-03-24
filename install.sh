#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"
BACKUP_ROOT=""
DO_BACKUP=1
INCLUDE_OPTIONAL=0

DEFAULT_PACKAGES=(
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

OPTIONAL_PACKAGES=(
  Wallpapers
  steam
)

usage() {
  cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --all
  ./install.sh hypr kitty fish
  ./install.sh --target /some/path
  ./install.sh --list

Options:
  --all         install optional packages too (Wallpapers, steam)
  --no-backup   do not move conflicting files before stow
  --target DIR  install into DIR instead of $HOME
  --list        print available packages
  -h, --help    show this help
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_known_package() {
  local wanted="$1"
  local pkg
  for pkg in "${DEFAULT_PACKAGES[@]}" "${OPTIONAL_PACKAGES[@]}"; do
    [[ "$pkg" == "$wanted" ]] && return 0
  done
  return 1
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
  if [[ "$DO_BACKUP" -eq 1 && -z "$BACKUP_ROOT" ]]; then
    BACKUP_ROOT="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p -- "$BACKUP_ROOT"
  fi
}

backup_path() {
  local source_path="$1"
  local relpath="$2"

  if [[ "$DO_BACKUP" -ne 1 ]]; then
    return 0
  fi

  ensure_backup_root

  local backup_path="${BACKUP_ROOT}/${relpath}"
  mkdir -p -- "$(dirname -- "$backup_path")"
  mv -- "$source_path" "$backup_path"
  printf 'Backed up %s -> %s\n' "$source_path" "$backup_path"
}

backup_parent_conflicts() {
  local relpath="$1"
  local parent_rel
  parent_rel="$(dirname -- "$relpath")"

  [[ "$parent_rel" == "." ]] && return 0

  local built=""
  local part
  IFS='/' read -r -a parts <<< "$parent_rel"
  for part in "${parts[@]}"; do
    [[ -z "$part" ]] && continue
    if [[ -z "$built" ]]; then
      built="$part"
    else
      built="${built}/${part}"
    fi

    local target_path="${TARGET_DIR}/${built}"
    if [[ ( -e "$target_path" || -L "$target_path" ) && ! -d "$target_path" ]]; then
      backup_path "$target_path" "$built"
    fi
  done
}

backup_conflicts_for_package() {
  local package="$1"
  local package_dir="${REPO_DIR}/${package}"

  while IFS= read -r -d '' source_path; do
    local relpath="${source_path#${package_dir}/}"
    local target_path="${TARGET_DIR}/${relpath}"
    local current_target=""
    local desired_target=""

    should_ignore_relpath "$relpath" && continue
    backup_parent_conflicts "$relpath"

    if [[ -L "$target_path" ]]; then
      current_target="$(readlink -f -- "$target_path" || true)"
      desired_target="$(readlink -f -- "$source_path")"
      [[ "$current_target" == "$desired_target" ]] && continue
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
      backup_path "$target_path" "$relpath"
    fi
  done < <(find "$package_dir" -mindepth 1 ! -type d -print0)
}

parse_args() {
  PACKAGES=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        INCLUDE_OPTIONAL=1
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
        printf 'Default packages:\n'
        printf '  %s\n' "${DEFAULT_PACKAGES[@]}"
        printf 'Optional packages:\n'
        printf '  %s\n' "${OPTIONAL_PACKAGES[@]}"
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
        PACKAGES+=("$1")
        ;;
    esac
    shift
  done
}

main() {
  local pkg
  local packages_to_install=()
  local stow_args=()

  parse_args "$@"

  require_cmd stow
  require_cmd find

  mkdir -p -- "$TARGET_DIR"

  if [[ "${#PACKAGES[@]}" -gt 0 ]]; then
    for pkg in "${PACKAGES[@]}"; do
      is_known_package "$pkg" || die "Unknown package: $pkg"
      [[ -d "${REPO_DIR}/${pkg}" ]] || die "Package directory not found: ${pkg}"
      packages_to_install+=("$pkg")
    done
  else
    packages_to_install=("${DEFAULT_PACKAGES[@]}")
    if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
      packages_to_install+=("${OPTIONAL_PACKAGES[@]}")
    fi
  fi

  printf 'Installing packages into %s\n' "$TARGET_DIR"
  printf '  %s\n' "${packages_to_install[@]}"

  if [[ "$DO_BACKUP" -eq 1 ]]; then
    for pkg in "${packages_to_install[@]}"; do
      backup_conflicts_for_package "$pkg"
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

  stow "${stow_args[@]}" "${packages_to_install[@]}"

  if [[ -n "$BACKUP_ROOT" ]]; then
    printf 'Conflicting files were backed up to %s\n' "$BACKUP_ROOT"
  fi

  printf 'Done.\n'
}

main "$@"
