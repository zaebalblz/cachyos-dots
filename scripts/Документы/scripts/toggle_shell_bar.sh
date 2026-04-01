#!/bin/bash

WAYBAR_CONFIG="$HOME/.config/waybar/config-toggle.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style-toggle.css"

is_running() {
    pgrep -x "$1" >/dev/null 2>&1
}

start_quickshell() {
    killall -q waybar 2>/dev/null
    env QSG_RHI_BACKEND=opengl QSG_RENDER_LOOP=threaded \
        quickshell -c noctalia-shell > /tmp/noctalia.log 2>&1 &
}

start_waybar() {
    killall -q quickshell 2>/dev/null
    killall -q waybar 2>/dev/null

    if [[ -f "$WAYBAR_CONFIG" && -f "$WAYBAR_STYLE" ]]; then
        waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_STYLE" > /tmp/waybar-toggle.log 2>&1 &
        return
    fi

    waybar > /tmp/waybar.log 2>&1 &
}

if is_running quickshell; then
    start_waybar
elif is_running waybar; then
    start_quickshell
else
    start_quickshell
fi
