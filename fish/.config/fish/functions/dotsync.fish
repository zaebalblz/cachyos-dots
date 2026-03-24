function dotsync
    set REPO_DIR "$HOME/Документы/github-rep/my-dots"
    set CONFIGS fastfetch fish hypr kitty noctalia foot uwsm quickshell waybar waybar-mini
    set WALLPAPERS_SRC "$HOME/Pictures/Wallpapers"

    echo "🚀 Начинаю синхронизацию конфигов и обоев..."

    # Проверка существования репозитория
    if not test -d "$REPO_DIR"
        echo "❌ Ошибка: Директория репозитория $REPO_DIR не найдена!"
        return 1
    end

    # Создаем папку .config в репо, если её нет
    mkdir -p "$REPO_DIR/.config"

    # Синхронизация папок конфигов
    for dir in $CONFIGS
        if test -e "$HOME/.config/$dir"
            echo "📦 Синхронизирую $dir..."
            rsync -a --delete "$HOME/.config/$dir/" "$REPO_DIR/.config/$dir/"
        end
    end

    # Синхронизация папки .gemini (исключая секреты и временные файлы)
    if test -d "$HOME/.gemini"
        echo "🧠 Синхронизирую .gemini (память системы)..."
        mkdir -p "$REPO_DIR/.gemini"
        rsync -a --delete \
            --exclude="tmp/" \
            --exclude="history/" \
            --exclude="google_accounts.json" \
            --exclude="oauth_creds.json" \
            --exclude="installation_id" \
            "$HOME/.gemini/" "$REPO_DIR/.gemini/"
    end

    # Отдельно синхронизируем файлы в корне .config
    if test -f "$HOME/.config/starship.toml"
        echo "📄 Синхронизирую starship.toml..."
        cp "$HOME/.config/starship.toml" "$REPO_DIR/.config/"
    end

    # Синхронизация обоев
    if test -d "$WALLPAPERS_SRC"
        echo "🖼️  Синхронизирую обои из $WALLPAPERS_SRC..."
        # Создаем папку Wallpapers в репо, если её нет
        mkdir -p "$REPO_DIR/Wallpapers"
        rsync -a --delete "$WALLPAPERS_SRC/" "$REPO_DIR/Wallpapers/"
    else
        echo "⚠️  Папка с обоями $WALLPAPERS_SRC не найдена!"
    end

    # Синхронизация папки scripts
    if test -d "$HOME/Документы/scripts"
        echo "📜 Синхронизирую папку со скриптами..."
        mkdir -p "$REPO_DIR/scripts"
        rsync -a --delete \
            --exclude="__pycache__/" \
            --exclude="*.pyc" \
            --exclude="*.pyo" \
            "$HOME/Документы/scripts/" "$REPO_DIR/scripts/"
    else
        echo "⚠️  Папка со скриптами $HOME/Документы/scripts не найдена!"
    end

    # Переходим в репозиторий
    cd $REPO_DIR

    # Подтягиваем изменения из облака
    echo "📥 Проверяю обновления на GitHub..."
    git pull --rebase origin main

    # Проверяем наличие локальных изменений
    if git status --porcelain | grep -q .
        echo "📝 Обнаружены изменения, отправляю в GitHub..."
        git add .
        git commit -m "Auto-update configs & wallpapers: $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin main
        echo "✅ Синхронизация завершена успешно!"
    else
        echo "✨ Изменений не найдено, репозиторий уже актуален."
    end

    # Возвращаемся обратно
    cd -
end
