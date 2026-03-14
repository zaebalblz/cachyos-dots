function dots
    set STOW_DIR "$HOME/.dotfiles"
    if not test -d "$STOW_DIR"
        echo (set_color red)"❌ Ошибка: Директория $STOW_DIR не найдена!"(set_color normal)
        return 1
    end

    pushd "$STOW_DIR" > /dev/null

    # Проверка и установка правильного URL (на всякий случай)
    set -l current_repo (git remote get-url origin 2>/dev/null)
    if test "$current_repo" != "https://github.com/zaebalblz/cachyos-dots.git"
        echo (set_color yellow)"🔄 Обновляю URL репозитория на cachyos-dots..."(set_color normal)
        git remote set-url origin https://github.com/zaebalblz/cachyos-dots.git
    end

    echo (set_color cyan)"📦 Обновляю символические ссылки через Stow (~/.dotfiles)..."(set_color normal)
    # Используем --restow для обновления существующих ссылок
    stow -t ~ --ignore=".git|README.md" -R *

    if git status --porcelain | grep -q .
        echo (set_color yellow)"📝 Обнаружены изменения в конфигах. Синхронизирую с GitHub..."(set_color normal)

        # Определяем имя основной ветки
        set -l branch (git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        if test -z "$branch"
            set branch "main"
        end

        # Сначала фиксируем локальные изменения
        git add .
        set -l current_time (date "+%Y-%m-%d %H:%M:%S")
        git commit -m "Auto-update: $current_time"

        # Теперь подтягиваем изменения извне и пушим
        echo (set_color cyan)"📥 Подтягиваю изменения из GitHub..."(set_color normal)
        if not git pull --rebase origin $branch
            echo (set_color red)"❌ Ошибка при pull. Попробуйте разрешить конфликты вручную."(set_color normal)
            popd > /dev/null
            return 1
        end

        echo (set_color cyan)"📤 Отправляю изменения в GitHub..."(set_color normal)
        git push origin $branch
        echo (set_color green)"🚀 GitHub успешно обновлен (ветка $branch)!"(set_color normal)
    else
        echo (set_color blue)"✨ Изменений не найдено, локальные конфиги и GitHub синхронизированы."(set_color normal)
    end

    popd > /dev/null
    echo (set_color green)"✅ Все операции завершены успешно!"(set_color normal)
end
