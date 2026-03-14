#!/usr/bin/env bash

# 1. Подготовка: переходим на 9 рабочий стол и чистим старье
hyprctl dispatch workspace 9
pkill -f "dashboard-bad-apple"
pkill -f "dashboard-matrix"
pkill -f "dashboard-cava"
pkill -f "dashboard-pipes"
sleep 0.3

# 2. Запускаем первое окно (Bad Apple) - оно займет весь экран
kitty --class dashboard-bad-apple sh -c "fastfetch-bad-apple; exec bash" &
sleep 0.5

# 3. Делим экран пополам (разрезаем Bad Apple ПРАВОЙ стороной)
hyprctl dispatch layoutmsg presel r
# Запускаем Matrix в правую половину
kitty --class dashboard-matrix sh -c "cmatrix -C blue; exec bash" &
sleep 0.5

# 4. Теперь режем левую половину (Bad Apple) НИЖНЕЙ стороной
hyprctl dispatch focuswindow class:dashboard-bad-apple
hyprctl dispatch layoutmsg presel d
# Запускаем Cava вниз под Bad Apple
kitty --class dashboard-cava sh -c "cava; exec bash" &
sleep 0.5

# 5. Теперь режем правую половину (Matrix) НИЖНЕЙ стороной
hyprctl dispatch focuswindow class:dashboard-matrix
hyprctl dispatch layoutmsg presel d
# Запускаем Pipes вниз под Matrix
kitty --class dashboard-pipes sh -c "pipes.sh; exec bash" &

echo "Дашборд собран!"
