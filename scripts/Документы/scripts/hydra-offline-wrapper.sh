#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 %command%" >&2
  exit 2
fi

env_args=()
cmd_args=()
found_command=0

for arg in "$@"; do
  if [ "$found_command" -eq 0 ] && [[ "$arg" == *=* ]]; then
    env_args+=("$arg")
    continue
  fi

  found_command=1
  cmd_args+=("$arg")
done

if [ "${#cmd_args[@]}" -eq 0 ]; then
  echo "No command to execute" >&2
  exit 2
fi

exec env "${env_args[@]}" \
  unshare --user --map-root-user --net \
  sh -c 'ip link set lo up; exec "$@"' \
  sh "${cmd_args[@]}"
