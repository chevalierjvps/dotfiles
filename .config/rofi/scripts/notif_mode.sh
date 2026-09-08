#!/usr/bin/env bash
# Rofi script-mode: gerenciador de notificações (mako). Adicionar ao modi do
# rofi como "notif:~/.config/rofi/scripts/notif_mode.sh"
set -u

list() {
    echo -en "\0prompt\x1fnotificações\n"

    if makoctl mode | grep -qx "do-not-disturb"; then
        printf '%s Não Perturbe: ligado (clique pra desligar)\0info\x1f__toggle_dnd\n' "$(printf '')"
    else
        printf '%s Não Perturbe: desligado (clique pra ligar)\0info\x1f__toggle_dnd\n' "$(printf '')"
    fi

    printf '%s Limpar todas\0info\x1f__dismiss_all\n' "$(printf '')"
    printf '%s Restaurar última descartada\0info\x1f__restore\n' "$(printf '')"

    active="$(makoctl list -j 2>/dev/null)"
    count="$(printf '%s' "$active" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"
    if [[ "${count:-0}" -gt 0 ]]; then
        printf '%s' "$active" | python3 -c "
import json, sys
for n in json.load(sys.stdin):
    summary = (n.get('summary') or '').replace('\n', ' ')
    body = (n.get('body') or '').replace('\n', ' ')
    app = n.get('app_name') or '?'
    text = f'{app}: {summary} — {body}'[:90]
    print(f'{text}\x00info\x1f{n[\"id\"]}')
"
    fi
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" ]]; then
    case "$info" in
        __toggle_dnd)
            makoctl mode -t do-not-disturb >/dev/null 2>&1
            ;;
        __dismiss_all)
            makoctl dismiss --all >/dev/null 2>&1
            ;;
        __restore)
            makoctl restore >/dev/null 2>&1
            ;;
        "")
            ;;
        *)
            makoctl dismiss -n "$info" >/dev/null 2>&1
            ;;
    esac
fi

list
