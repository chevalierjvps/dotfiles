#!/usr/bin/env bash
# Rofi script-mode: cheatsheet de atalhos, lido direto do bind.conf (sempre
# atualizado, sem lista duplicada pra manter em dia). Selecionar copia a
# combinação de teclas pro clipboard.
set -u

bindfile="$HOME/.config/mango/bind.conf"

list() {
    echo -en "\0prompt\x1fatalhos\n"
    local section=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^#[[:space:]]*───[[:space:]]*(.+[^─])[[:space:]]*───[[:space:]]*$ ]]; then
            section="${BASH_REMATCH[1]}"
            printf '· %s\0nonselectable\x1ftrue\n' "$section"
        elif [[ "$line" =~ ^(mouse)?bind=([^,]+),([^,]+),(.*)$ ]]; then
            mods="${BASH_REMATCH[2]}"
            key="${BASH_REMATCH[3]}"
            action="${BASH_REMATCH[4]}"
            [[ "$mods" == "none" || "$mods" == "NONE" ]] && combo="$key" || combo="${mods}+${key}"
            printf '  %-22s %s\0info\x1f%s\n' "$combo" "$action" "$combo"
        fi
    done < "$bindfile"
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" && -n "$info" ]]; then
    printf '%s' "$info" | wl-copy
    exit 0
fi

list
