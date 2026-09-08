#!/usr/bin/env bash
# Screenshot sempre salvo em ~/Pictures/Screenshots — nunca só no clipboard.
# Uso: screenshot.sh full   -> tela inteira
#      screenshot.sh region -> seleção via slurp
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"

mode="${1:-region}"
stamp="$(date +%Y-%m-%d_%H-%M-%S)"

case "$mode" in
    full)
        file="$dir/${stamp}.png"
        grim "$file"
        wl-copy < "$file"
        ;;
    region)
        file="$dir/${stamp}-region.png"
        geom="$(slurp -b '#1a150f88' -c '#e8952dff')"
        [ -z "$geom" ] && exit 0
        grim -g "$geom" "$file"
        wl-copy < "$file"
        ;;
    *)
        echo "uso: screenshot.sh [full|region]" >&2
        exit 1
        ;;
esac
