#!/usr/bin/env bash

# Скрипт через ydotool (эмулирует ввод на уровне ядра)
# key 56 = Alt (Left)
# key 28 = Enter
# key 276 = Mouse Forward (или btn_forward)

# Зажимаем Alt и Enter, кликаем мышкой, отпускаем всё
# 56:1 - зажать Alt
# 28:1 - зажать Enter
# 273:1 - зажать боковую (btn_forward)
# :0 - отпустить

ydotool key 56:1 28:1 273:1 273:0 28:0 56:0
