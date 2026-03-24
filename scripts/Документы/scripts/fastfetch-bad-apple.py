#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import pty
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[3]
BASE_DIR = os.path.expanduser("~/.config/fastfetch/bad-apple-data/frames-ascii")
if not os.path.exists(BASE_DIR):
    BASE_DIR = str(REPO_ROOT / "fastfetch/.config/fastfetch/bad-apple-data/frames-ascii")

ORIGINAL_CONFIG = os.path.expanduser("~/.config/fastfetch/config.jsonc")
TEMP_CONFIG = os.path.expanduser("~/.config/fastfetch/temp_no_logo.jsonc")

def prepare_temp_config():
    if not os.path.exists(ORIGINAL_CONFIG): return
    with open(ORIGINAL_CONFIG, 'r') as f:
        content = f.read()
    if '"logo": {' in content:
        # Принудительно отключаем логотип, сохраняя остальное
        new_content = content.replace('"logo": {', '"logo": {\n\t\t"type": "none",')
        with open(TEMP_CONFIG, 'w') as f:
            f.write(new_content)

def get_fastfetch_info_with_color():
    # Используем pty.openpty() чтобы обмануть fastfetch и получить цвета
    master, slave = pty.openpty()
    try:
        # Запускаем fastfetch с флагом --color white для принудиловки
        process = subprocess.Popen(
            ["fastfetch", "-c", TEMP_CONFIG, "--color", "white"],
            stdout=slave,
            stderr=slave,
            close_fds=True
        )
        os.close(slave)
        
        output = b""
        while True:
            try:
                data = os.read(master, 1024)
                if not data: break
                output += data
            except OSError:
                break
        
        process.wait()
        return output.decode('utf-8', errors='ignore').splitlines()
    finally:
        os.close(master)

def play_bad_apple():
    prepare_temp_config()
    if not os.path.exists(BASE_DIR):
        print("Error: Frames directory not found.")
        return

    frames = sorted([f for f in os.listdir(BASE_DIR) if f.endswith(".txt")])
    if not frames: return

    # Получаем инфо-блок со всеми ANSI-цветами
    info_lines = get_fastfetch_info_with_color()
    
    # Скрываем курсор
    sys.stdout.write("\033[?25l")
    sys.stdout.flush()
    
    # Настройки
    LOGO_WIDTH = 42
    CROP_START = 22 
    
    try:
        start_time = time.time()
        fps = 30
        frame_duration = 1.0 / fps
        
        # Предзагружаем инфо-блок для скорости
        # Убираем возможные пустые строки в начале/конце
        info_lines = [l for l in info_lines if l.strip()]
        
        for i, frame_file in enumerate(frames):
            frame_path = os.path.join(BASE_DIR, frame_file)
            with open(frame_path, 'r') as f:
                raw_lines = f.readlines()
            
            scaled_lines = raw_lines[::2]
            output = "\033[H"
            max_lines = max(len(scaled_lines), len(info_lines))
            
            for j in range(max_lines):
                # Логотип
                if j < len(scaled_lines):
                    line = scaled_lines[j].strip("\n")
                    # Берем центральную часть кадра и заменяем @ на #
                    logo_part = line[CROP_START:CROP_START+LOGO_WIDTH].replace('@', '#')
                    logo_part = f"{logo_part:<{LOGO_WIDTH}}"
                else:
                    logo_part = " " * LOGO_WIDTH
                
                # Инфо (смещаем на 2 строки вниз для центровки)
                info_idx = j - 2 
                info_part = info_lines[info_idx] if 0 <= info_idx < len(info_lines) else ""
                
                # Выводим логотип и информацию (информация будет с цветами)
                output += f" {logo_part}  {info_part}\033[K\n"
            
            sys.stdout.write(output)
            sys.stdout.flush()
            
            # Синхронизация
            elapsed = time.time() - start_time
            expected = (i + 1) * frame_duration
            sleep_time = expected - elapsed
            if sleep_time > 0:
                time.sleep(sleep_time)
            elif i % 100 == 0:
                start_time = time.time() - (i * frame_duration)
                
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write("\033[?25h\033[2J\033[H")
        sys.stdout.flush()

if __name__ == "__main__":
    play_bad_apple()
