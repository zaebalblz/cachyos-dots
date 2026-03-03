function dots
    set STOW_DIR "$HOME/Документы/stow-dots"
    
    # Проверка существования папки
    if not test -d "$STOW_DIR"
        echo (set_color red)"❌ Ошибка: Директория $STOW_DIR не найдена!"(set_color normal)
        return 1
    end

    # Переходим в папку
    pushd "$STOW_DIR" > /dev/null

    # 1. Сначала применяем Stow (локально)
    echo (set_color cyan)"📦 Обновляю символические ссылки через Stow..."(set_color normal)
    stow -t ~ --ignore=".git|README.md" *

    # 2. Проверяем наличие изменений для Git
    if git status --porcelain | grep -q .
        echo (set_color yellow)"📝 Обнаружены изменения в конфигах. Отправляю на GitHub..."(set_color normal)
        
        # Подтягиваем изменения (на всякий случай)
        git pull --rebase origin main
        
        # Добавляем и пушим
        git add .
        git commit -m "Auto-update: (date '+%Y-%m-%d %H:%M:%S')"
        git push origin main
        
        echo (set_color green)"🚀 GitHub успешно обновлен!"(set_color normal)
    else
        echo (set_color blue)"✨ Изменений не найдено, GitHub уже актуален."(set_color normal)
    end

    # Возвращаемся обратно
    popd > /dev/null
    
    echo (set_color green)"✅ Готово!"(set_color normal)
end
