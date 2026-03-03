#!/bin/bash

# Получаем PID активного окна через hyprctl
pid=$(hyprctl activewindow -j | jq -r '.pid')

# Если PID найден и это число, убиваем процесс
if [[ $pid =~ ^[0-9]+$ ]]; then
    kill -9 "$pid"
fi
