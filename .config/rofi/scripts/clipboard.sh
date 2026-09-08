#!/usr/bin/env bash
# Clipboard manager (cliphist) via rofi, com miniaturas reais para prints/
# imagens em vez do placeholder "[[ binary data ... ]]".
set -euo pipefail

cache_dir="$HOME/.cache/cliphist-thumbs"
mkdir -p "$cache_dir"

prune_cache() {
    local ids
    ids="$(cliphist list | cut -f1)"
    for f in "$cache_dir"/*.png; do
        [[ -e "$f" ]] || continue
        id="$(basename "$f" .png)"
        grep -qx "$id" <<< "$ids" || rm -f "$f"
    done
}
prune_cache

build_menu() {
    cliphist list | while IFS=$'\t' read -r id rest; do
        if [[ "$rest" == "[[ binary data"*"png"* || "$rest" == "[[ binary data"*"jpg"* || "$rest" == "[[ binary data"*"jpeg"* ]]; then
            thumb="$cache_dir/${id}.png"
            if [[ ! -s "$thumb" ]]; then
                cliphist decode "$id" 2>/dev/null | magick - -resize 128x128 "$thumb" 2>/dev/null || true
            fi
            if [[ -s "$thumb" ]]; then
                printf '%s\t%s\0icon\x1f%s\n' "$id" "$rest" "$thumb"
                continue
            fi
        fi
        printf '%s\t%s\n' "$id" "$rest"
    done
}

chosen="$(build_menu | rofi -dmenu -show-icons -i -p "Clipboard" -theme ~/.config/rofi/amberglow.rasi)"
[[ -z "$chosen" ]] && exit 0
printf '%s\n' "$chosen" | cliphist decode | wl-copy
