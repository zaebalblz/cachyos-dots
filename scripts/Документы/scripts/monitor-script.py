#!/usr/bin/env python3
from pathlib import Path
import subprocess

FILE = Path("~/.config/hypr/hyprland/monitor.conf").expanduser()

STATE_A = """\
monitor=DP-3,1920x1080@120,1920x0,1
monitor=eDP-1,1920x1080@60,0x0,1,
"""

STATE_B = """\
monitor=DP-3,1920x1080@60,1920x0,1
monitor=eDP-1,1920x1080@60,0x0,1,
"""

text = FILE.read_text()

if "DP-3,1920x1080@120" in text:
    FILE.write_text(STATE_B)
    subprocess.run(["hyprctl", "reload"])
    print("Переключено: 120Hz → 60Hz")
elif "DP-3,1920x1080@60" in text:
    FILE.write_text(STATE_A)
    subprocess.run(["hyprctl", "reload"])
    print("Переключено: 60Hz → 120Hz")
else:
    raise RuntimeError("Не найдено ожидаемое состояние в monitor.conf")
