#!/usr/bin/env bash
# Pac-Man comendo pastilhas = atualizações pendentes (pacman + AUR).
# Streaming contínuo (sem "interval" no waybar) pra animar de verdade —
# CSS @keyframes não anima de forma confiável nesse build do waybar/GTK.
set -u

cache="$HOME/.cache/waybar-pacman-updates"
lock="$HOME/.cache/waybar-pacman-updates.lock"
max_age=1800

[[ -f "$cache" ]] || echo "0 0 0" > "$cache"

refresh() {
    local official aur
    official="$(checkupdates 2>/dev/null | wc -l)"
    aur="$(paru -Qua 2>/dev/null | wc -l)"
    echo "$((official + aur)) $official $aur" > "$cache"
    rm -f "$lock"
}

frame=0
while true; do
    age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
    if (( age >= max_age )) && [[ ! -f "$lock" ]]; then
        touch "$lock"
        ( refresh & disown ) 2>/dev/null
    fi

    read -r total official aur < "$cache"

    if (( frame % 2 == 0 )); then
        mouth=$'󰮯'
    else
        mouth=$''
    fi
    frame=$((frame + 1))

    if (( total > 0 )); then
        printf '{"text":"%s %d","tooltip":"%d atualizações pendentes (%d oficiais, %d AUR)\\nclique: atualizar","class":"pending"}\n' \
            "$mouth" "$total" "$total" "$official" "$aur"
    else
        printf '{"text":"%s","tooltip":"sistema atualizado","class":"uptodate"}\n' "$mouth"
    fi

    sleep 0.4
done
