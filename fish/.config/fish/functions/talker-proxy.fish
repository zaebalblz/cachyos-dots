function talker-proxy
    set -x WINEPREFIX /home/linuxoed/.config/hydralauncher/wine-prefixes/4500
    set -x WINEFSYNC 1
    set -x WINEESYNC 1
    "/home/linuxoed/.local/share/Steam/compatibilitytools.d/UMU-Proton-10.0-4/files/bin/wine" "/mnt/game-linux/hydra-game/TALKER_Proxy/proxy_app.exe" --run
end
