function dots
    set STOW_DIR "$HOME/.dotfiles"
    if not test -d "$STOW_DIR"
        echo (set_color red)"❌ Ошибка: Директория $STOW_DIR не найдена!"(set_color normal)
        return 1
    end
    pushd "$STOW_DIR" > /dev/null
    echo (set_color cyan)"📦 Обновляю символические ссылки через Stow (~/.dotfiles)..."(set_color normal)
    stow -t ~ --ignore=".git|README.md" *
    if git status --porcelain | grep -q .
        echo (set_color yellow)"📝 Обнаружены изменения в конфигах. Отправляю на GitHub..."(set_color normal)
        git pull --rebase origin main
        git add .
        set -l current_time (date "+%Y-%m-%d %H:%M:%S")
        git commit -m "Auto-update: $current_time"
        git push origin main
        echo (set_color green)"🚀 GitHub успешно обновлен!"(set_color normal)
    else
        echo (set_color blue)"✨ Изменений не найдено, GitHub уже актуален."(set_color normal)
    end
    popd > /dev/null
    echo (set_color green)"✅ Готово!"(set_color normal)
end
