#!/usr/bin/env bash
# Sininho de notificações: contagem de ativas + estado do Não Perturbe.
# Streaming contínuo (mesmo padrão de tags.sh/mic.sh) — makoctl não tem um
# comando "subscribe", então poll leve a cada 2s.
set -u

bell=$''
bell_slash=$''

while true; do
    count="$(makoctl list -j 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"
    count="${count:-0}"

    if makoctl mode 2>/dev/null | grep -qx "do-not-disturb"; then
        printf '{"text":"%s","tooltip":"Não Perturbe ligado","class":"dnd"}\n' "$bell_slash"
    elif (( count > 0 )); then
        printf '{"text":"%s %d","tooltip":"%d notificação(ões)","class":"active"}\n' "$bell" "$count" "$count"
    else
        printf '{"text":"%s","tooltip":"sem notificações","class":"empty"}\n' "$bell"
    fi

    sleep 2
done
