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
./install.sh
```

`install.sh` по умолчанию:

- ставит системные пакеты через `pacman`
- при наличии `yay` или `paru` ставит AUR/внешние пакеты
- создаёт нужные пользовательские директории
- затем применяет все stow-пакеты, включая `Wallpapers` и `steam`

Если нужны только конфиги без установки пакетов, тогда нужен `gnu stow`.

Для Arch/CachyOS:

```bash
sudo pacman -S stow
```

Клонирование и установка только конфигов:

```bash
git clone https://github.com/zaebalblz/cachyos-dots.git
cd cachyos-dots
./install.sh --configs-only
```

Минимальный профиль без extra desktop/gaming-приложений и без опциональных stow-пакетов:

```bash
./install.sh --minimal
```

Установка только выбранных stow-пакетов:

```bash
./install.sh hypr kitty fish
```

## Что делает `install.sh`

- по умолчанию ставит системные зависимости для этого окружения через `pacman`
- при наличии `yay`/`paru` добирает AUR/helper-пакеты вроде `bibata-cursor-theme-bin`, `portproton`, `pipes.sh`
- затем запускает `stow` из корня репозитория
- по умолчанию применяет все stow-пакеты: `btop fastfetch fish foot hypr kitty noctalia scripts waybar Wallpapers steam`
- перед установкой переносит конфликтующие файлы в `~/.dotfiles-backup/<timestamp>`
- игнорирует runtime-артефакты вроде `__pycache__`, `*.pyc`, `*.swp`, `*.bak`, `fish_variables`
- поддерживает режимы `--minimal`, `--packages-only`, `--configs-only`, `--no-aur`, `--target DIR`

## Что делает `bootstrap.sh`

- это thin-wrapper для совместимости
- просто проксирует аргументы в `./install.sh`
- нужен только если старые заметки или команды всё ещё ссылаются на `bootstrap.sh`

Минимальный вариант без лишних приложений:

```bash
./install.sh --minimal
```

Только пакеты, без применения конфигов:

```bash
./install.sh --packages-only
```

## Ограничения

- Это не универсальные dotfiles для любого дистрибутива. Основная среда здесь: CachyOS, Hyprland, kitty, waybar, Noctalia, quickshell.
- Некоторые сценарии и бинды завязаны на `~/Документы/scripts`, потому что такой путь используется в моём рабочем окружении.
- `install.sh` совмещает установку пакетов и применение Stow в одном сценарии.
- `install.sh` ориентирован на Arch/CachyOS и не рассчитан на Debian/Ubuntu/Fedora.
- AppImage-файлы вроде YouTube Music и osu не скачиваются автоматически: для них в биндах используются локальные пути в `~/Документы/appimage/`.
