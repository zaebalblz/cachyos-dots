function beammod --description 'Install BeamNG mods into the native Linux mods directory'
    set -l mods_dir "$HOME/.local/share/BeamNG/BeamNG.drive/current/mods"

    if not test -d "$mods_dir"
        echo "BeamNG mods directory not found: $mods_dir"
        return 1
    end

    if test (count $argv) -eq 0
        echo "Usage: beammod mod1.zip [mod2.zip ...]"
        return 1
    end

    set -l failed 0

    for mod in $argv
        set -l source_path "$mod"

        if not test -e "$source_path"
            echo "File not found: $source_path"
            set failed 1
            continue
        end

        if test (path extension "$source_path") != ".zip"
            echo "Skipped (not a .zip): $source_path"
            set failed 1
            continue
        end

        cp -f "$source_path" "$mods_dir"/
        if test $status -ne 0
            echo "Copy failed: $source_path"
            set failed 1
            continue
        end

        echo "Installed: "(path basename "$source_path")
    end

    return $failed
end
