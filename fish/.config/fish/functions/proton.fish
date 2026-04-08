function proton --description 'Запуск Windows-программы через GE-Proton'
    if not command -q umu-run
        echo "Ошибка: umu-run не найден."
        return 1
    end

    if test (count $argv) -lt 1
        echo "Использование: proton /путь/к/программе.exe [аргументы]"
        return 1
    end

    set -l exe_path "$argv[1]"

    if not test -e "$exe_path"
        echo "Ошибка: файл не найден: $exe_path"
        return 1
    end

    set -l resolved_exe (realpath -- "$exe_path" 2>/dev/null)
    if test -z "$resolved_exe"
        echo "Ошибка: не удалось определить путь: $exe_path"
        return 1
    end

    set -l prefix_dir "$HOME/Games/umu/shared-ge-proton"

    env \
        WINEPREFIX="$prefix_dir" \
        PROTONPATH="GE-Proton" \
        umu-run "$resolved_exe" $argv[2..-1]
end
