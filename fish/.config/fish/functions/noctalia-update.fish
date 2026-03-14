function noctalia-update
    cd ~/.config/quickshell/noctalia-shell
    echo (set_color cyan)"🔄 Обновляю Noctalia-shell до последнего коммита..."(set_color normal)
    git fetch origin
    git reset --hard origin/main
    echo (set_color green)"✅ Готово! Установлена самая свежая версия."(set_color normal)
end
