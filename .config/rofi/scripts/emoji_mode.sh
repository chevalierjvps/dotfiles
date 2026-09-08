#!/usr/bin/env bash
# Rofi script-mode: emoji picker, usando os dados oficiais do Unicode já
# instalados via oh-my-zsh. Selecionar copia o emoji pro clipboard.
set -u

data="/usr/share/oh-my-zsh/plugins/emoji/emoji-data.txt"

list() {
    echo -en "\0prompt\x1femoji\n"
    grep "; fully-qualified" "$data" | sed -E 's/^[0-9A-Fa-f ]+; fully-qualified *# (\S+) (.*)$/\1\t\2/' \
        | while IFS=$'\t' read -r emoji name; do
            printf '%s  %s\0info\x1f%s\n' "$emoji" "$name" "$emoji"
        done
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" && -n "$info" ]]; then
    printf '%s' "$info" | wl-copy
    exit 0
fi

list
