#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

printf '[bootstrap] bootstrap.sh is kept as a compatibility wrapper.\n'
printf '[bootstrap] Delegating to install.sh with the same arguments.\n'

exec "${REPO_DIR}/install.sh" "$@"
