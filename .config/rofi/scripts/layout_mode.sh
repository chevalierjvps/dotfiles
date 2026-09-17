#!/usr/bin/env bash
# Rofi script-mode: troca o layout do monitor focado (mmsg dispatch setlayout).
set -u

# símbolo · nome interno · rótulo
LAYOUTS=(
    "T|tile|Tile (mestre + pilha)"
    "S|scroller|Scroller"
    "G|grid|Grid"
    "M|monocle|Monocle (janela única)"
    "K|deck|Deck (cartas)"
    "CT|center_tile|Centralizado"
    "RT|right_tile|Mestre à direita"
    "VS|vertical_scroller|Scroller vertical"
    "VT|vertical_tile|Tile vertical"
    "VG|vertical_grid|Grid vertical"
    "VK|vertical_deck|Deck vertical"
    "DW|dwindle|Dwindle"
    "F|fair|Fair"
    "VF|vertical_fair|Fair vertical"
)

current_symbol() {
    mmsg get all-monitors 2>/dev/null | jq -r '
        .monitors[] | select(.active == true) | .layout_symbol' 2>/dev/null
}

list() {
    echo -en "\0prompt\x1flayout\n"
    local cur
    cur="$(current_symbol)"
    for entry in "${LAYOUTS[@]}"; do
        IFS='|' read -r symbol name label <<<"$entry"
        if [[ "$symbol" == "$cur" ]]; then
            printf '● %-22s [%s]\0info\x1f%s\n' "$label" "$symbol" "$name"
        else
            printf '○ %-22s [%s]\0info\x1f%s\n' "$label" "$symbol" "$name"
        fi
    done
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" && -n "$info" ]]; then
    mmsg dispatch "setlayout,$info" >/dev/null 2>&1
    exit 0
fi

list
