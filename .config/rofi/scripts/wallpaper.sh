#!/usr/bin/env bash
# Seletor de wallpaper via rofi (Amberglow), com miniaturas.
set -euo pipefail

wall_dir="$HOME/Pictures/Wallpapers"
cache_dir="$HOME/.cache/rofi-wallpapers-thumbs"
mkdir -p "$cache_dir"

build_menu() {
    find "$wall_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort | while read -r path; do
        name="$(basename "$path")"
        thumb="$cache_dir/${name%.*}.png"
        if [[ ! -s "$thumb" || "$path" -nt "$thumb" ]]; then
            magick "$path" -resize 300x300^ -gravity center -extent 300x300 "$thumb" 2>/dev/null || continue
        fi
        printf '%s\0icon\x1f%s\n' "$name" "$thumb"
    done
}

chosen="$(build_menu | rofi -dmenu -i -p "Wallpaper" -theme ~/.config/rofi/wallpaper.rasi)"
[[ -z "$chosen" ]] && exit 0

new_path="$wall_dir/$chosen"
[[ -f "$new_path" ]] || exit 0

pkill -x swaybg 2>/dev/null || true
setsid swaybg -i "$new_path" -m fill >/dev/null 2>&1 &

# persiste a escolha pro próximo login (awk evita problemas de escaping do sed)
autostart="$HOME/.config/mango/autostart.sh"
awk -v np="$new_path" '
    /^swaybg -i / { print "swaybg -i \"" np "\" -m fill >/dev/null 2>&1 &"; next }
    { print }
' "$autostart" > "$autostart.tmp" && chmod +x "$autostart.tmp" && mv "$autostart.tmp" "$autostart"

