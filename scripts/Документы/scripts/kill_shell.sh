#!/bin/bash
# Kill any active shell and Waybar (cleanup)
killall -9 quickshell 2>/dev/null
killall -9 waybar 2>/dev/null
dms kill 2>/dev/null # Final cleanup just in case
