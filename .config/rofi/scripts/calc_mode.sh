#!/usr/bin/env bash
# Rofi script-mode: Calculator via qalc (libqalculate)
set -u

retv="${ROFI_RETV:-0}"

case "$retv" in
    1)
        # Enter on a calculated result -> copy to clipboard
        info="${ROFI_INFO:-}"
        [[ -n "$info" ]] && printf '%s' "$info" | wl-copy
        exit 0
        ;;
    2)
        # Enter on typed expression -> evaluate
        echo -en "\0prompt\x1f󰪚\n"
        expr="$1"
        result="$(qalc -t "$expr" 2>/dev/null)"
        if [[ -z "$result" ]]; then
            printf 'invalid expression\0nonselectable\x1ftrue\n'
        else
            printf '%s = %s\0info\x1f%s\n' "$expr" "$result" "$result"
        fi
        ;;
    *)
        echo -en "\0prompt\x1f󰪚\n"
        echo -en "\0message\x1fType an expression and press Enter\n"
        ;;
esac
