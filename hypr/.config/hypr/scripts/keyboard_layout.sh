#!/usr/bin/env bash

set -euo pipefail

state_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-last-pair-layout"

get_keyboard_field() {
    local field="$1"

    hyprctl -j devices | jq -r --arg field "$field" '
        if (.keyboards | length) == 0 then
            empty
        else
            ((.keyboards[] | select(.main == true)) // .keyboards[0])[$field]
        end
    '
}

get_device() {
    local device
    device="$(get_keyboard_field name)"

    if [[ -z "$device" || "$device" == "null" ]]; then
        printf 'Не удалось определить клавиатуру Hyprland\n' >&2
        exit 1
    fi

    printf '%s\n' "$device"
}

get_active_layout() {
    local active
    active="$(get_keyboard_field active_keymap | tr '[:upper:]' '[:lower:]')"

    case "$active" in
        *ukrainian*|*україн*|*украин*)
            printf 'ua\n'
            ;;
        *russian*|*русс*|*росій*)
            printf 'ru\n'
            ;;
        *english*|*англ*|*latin*)
            printf 'us\n'
            ;;
        *)
            printf 'unknown\n'
            ;;
    esac
}

get_last_pair_layout() {
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
        return
    fi

    printf 'us\n'
}

set_layout() {
    local device="$1"
    local index="$2"

    hyprctl switchxkblayout "$device" "$index" >/dev/null
}

toggle_pair() {
    local device current next next_index
    device="$(get_device)"
    current="$(get_active_layout)"

    case "$current" in
        us)
            next="ru"
            next_index=1
            ;;
        ru)
            next="us"
            next_index=0
            ;;
        ua|unknown)
            if [[ "$(get_last_pair_layout)" == "ru" ]]; then
                next="us"
                next_index=0
            else
                next="ru"
                next_index=1
            fi
            ;;
    esac

    set_layout "$device" "$next_index"
    printf '%s\n' "$next" > "$state_file"
}

set_ukrainian() {
    local device
    device="$(get_device)"
    set_layout "$device" 2
}

case "${1:-}" in
    toggle-pair)
        toggle_pair
        ;;
    ua)
        set_ukrainian
        ;;
    *)
        printf 'Использование: %s {toggle-pair|ua}\n' "$0" >&2
        exit 2
        ;;
esac
