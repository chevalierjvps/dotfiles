#!/usr/bin/env bash
# Indicador de microfone (source padrão): ícone muda entre normal/mudo,
# atualizado em tempo real via pactl subscribe (mesmo padrão de tags.sh).
set -u

emit() {
    local raw muted vol percent icon class
    raw="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"
    [ -z "$raw" ] && { printf '{"text":"","tooltip":"sem entrada de áudio"}\n'; return; }
    vol="$(awk '{print $2}' <<<"$raw")"
    percent="$(awk -v v="$vol" 'BEGIN{printf "%d", v*100}')"
    if grep -q MUTED <<<"$raw"; then
        icon=$''
        class="muted"
    else
        icon=$''
        class="unmuted"
    fi
    printf '{"text":"%s  %s%%","tooltip":"Microfone (clique: mutar)","class":"%s"}\n' "$icon" "$percent" "$class"
}

emit
pactl subscribe 2>/dev/null | grep --line-buffered -E "on source|on server" | while read -r _; do
    emit
done
