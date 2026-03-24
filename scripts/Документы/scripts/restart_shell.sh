#!/bin/bash
# Always restart Noctalia-shell with forced GPU acceleration
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/kill_shell.sh"
env QSG_RHI_BACKEND=opengl QSG_RENDER_LOOP=threaded quickshell -c noctalia-shell > /tmp/noctalia.log 2>&1 &
