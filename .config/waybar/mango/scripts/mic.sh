#!/usr/bin/env bash
# Microphone indicator (default source): real-time updates via pactl subscribe
set -u

emit() {
    local raw muted vol percent icon class
    raw="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"
    [ -z "$raw" ] && { printf '{"text":"","tooltip":"No audio input"}\n'; return; }
    vol="$(awk '{print $2}' <<<"$raw")"
    percent="$(awk -v v="$vol" 'BEGIN{printf "%d", v*100}')"
    if grep -q MUTED <<<"$raw"; then
        icon=$''
        class="muted"
    else
        icon=$''
        class="unmuted"
    fi
    printf '{"text":"%s  %s%%","tooltip":"Microphone (click to toggle mute)","class":"%s"}\n' "$icon" "$percent" "$class"
}

emit
pactl subscribe 2>/dev/null | grep --line-buffered -E "on source|on server" | while read -r _; do
    emit
done
