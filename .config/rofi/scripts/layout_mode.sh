#!/usr/bin/env bash
# Rofi script-mode: Switch layout for focused monitor (mmsg dispatch setlayout)
set -u

# symbol | internal_name | label
LAYOUTS=(
    "T|tile|Tile (master + stack)"
    "S|scroller|Scroller"
    "G|grid|Grid"
    "M|monocle|Monocle (single window)"
    "K|deck|Deck (stacked cards)"
    "CT|center_tile|Center Tile"
    "RT|right_tile|Right Tile"
    "VS|vertical_scroller|Vertical Scroller"
    "VT|vertical_tile|Vertical Tile"
    "VG|vertical_grid|Vertical Grid"
    "VK|vertical_deck|Vertical Deck"
    "DW|dwindle|Dwindle"
    "F|fair|Fair"
    "VF|vertical_fair|Vertical Fair"
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
