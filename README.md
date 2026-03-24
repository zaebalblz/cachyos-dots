# cachyos-dots

Stow-репозиторий с моими конфигами для CachyOS/Hyprland.

## Архитектура

Корень репозитория содержит отдельные stow-пакеты:

- `hypr` -> `~/.config/hypr`
- `fish` -> `~/.config/fish`
- `kitty` -> `~/.config/kitty`
- `foot` -> `~/.config/foot`
- `fastfetch` -> `~/.config/fastfetch`
- `btop` -> `~/.config/btop`
- `noctalia` -> `~/.config/noctalia`
- `waybar` -> `~/.config/waybar` и `~/.config/waybar-mini`
- `scripts` -> `~/Документы/scripts`
- `Wallpapers` -> `~/Pictures/Wallpapers`
- `steam` -> `~/.local/bin` и `~/.local/share/SLSsteam`

То есть репозиторий уже построен под GNU Stow: каждая папка в корне является отдельным пакетом, который симлинкуется в `$HOME`.

## Быстрая установка

Для полной установки зависимостей и конфигов:

```bash
git clone https://github.com/zaebalblz/cachyos-dots.git
cd cachyos-dots
./bootstrap.sh
```

`bootstrap.sh`:

- ставит системные пакеты через `pacman`
- при наличии `yay` или `paru` ставит AUR/внешние пакеты
- создаёт нужные пользовательские директории
- затем запускает `install.sh --all`

Если нужны только конфиги без установки пакетов, тогда нужен `gnu stow`.

Для Arch/CachyOS:

```bash
sudo pacman -S stow
```

Клонирование и установка только конфигов:

```bash
git clone https://github.com/zaebalblz/cachyos-dots.git
cd cachyos-dots
./install.sh
```

Установка вместе с обоями и Steam-файлами:

```bash
./install.sh --all
```

Установка только выбранных пакетов:

```bash
./install.sh hypr kitty fish
```

## Что делает `install.sh`

- запускает `stow` из корня репозитория
- по умолчанию применяет базовые stow-пакеты: `btop fastfetch fish foot hypr kitty noctalia scripts waybar`
- умеет ставить опциональные пакеты: `Wallpapers` и `steam`
- перед установкой переносит конфликтующие файлы в `~/.dotfiles-backup/<timestamp>`
- игнорирует runtime-артефакты вроде `__pycache__`, `*.pyc`, `*.swp`, `*.bak`, `fish_variables`

## Что делает `bootstrap.sh`

- ставит базовый стек для этого окружения: Hyprland, kitty, fish, fastfetch, btop, waybar, Noctalia/quickshell, clipboard/media/system utilities
- по умолчанию ставит и дополнительные desktop/gaming-программы из моих биндов: `telegram-desktop`, `discord`, `steam`, `prismlauncher`, `obs-studio`, `godot`, `lutris-git`, `nemo`
- при наличии `yay`/`paru` добирает пакеты, которых нет в sync DB, например `portproton` и `pipes.sh`
- после установки пакетов применяет все stow-пакеты через `install.sh --all`

Минимальный вариант без лишних приложений:

```bash
./bootstrap.sh --minimal
```

Только пакеты, без применения конфигов:

```bash
./bootstrap.sh --packages-only
```

## Ограничения

- Это не универсальные dotfiles для любого дистрибутива. Основная среда здесь: CachyOS, Hyprland, kitty, waybar, Noctalia, quickshell.
- Некоторые сценарии и бинды завязаны на `~/Документы/scripts`, потому что такой путь используется в моём рабочем окружении.
- `install.sh` создаёт симлинки, а системные зависимости ставит уже `bootstrap.sh`.
- `bootstrap.sh` ориентирован на Arch/CachyOS и не рассчитан на Debian/Ubuntu/Fedora.
- AppImage-файлы вроде YouTube Music и osu не скачиваются автоматически: для них в биндах используются локальные пути в `~/Документы/appimage/`.
