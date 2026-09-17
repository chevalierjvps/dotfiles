#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"

case "$action" in
    up)
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        mic_raw="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"
        if [[ "$mic_raw" =~ \[MUTED\] ]]; then
            notify-send -h string:synchronous:mic -t 1200 -a "volume" "󰍭 Mic: Muted" ""
        else
            notify-send -h string:synchronous:mic -t 1200 -a "volume" "󰍬 Mic: Active" ""
        fi
        exit 0
        ;;
    *)
        echo "Usage: $0 {up|down|mute|mic-mute}"
        exit 1
        ;;
esac

raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"

if [[ "$raw" =~ \[MUTED\] ]]; then
    notify-send -h string:synchronous:volume -t 1200 -a "volume" "󰝟 Volume: Muted" ""
else
    vol_float="$(echo "$raw" | awk '{print $2}')"
    vol_percent="$(awk -v v="$vol_float" 'BEGIN { printf "%.0f", v * 100 }')"

    icon="󰕾"
    if [ "$vol_percent" -eq 0 ]; then
        icon="󰝟"
    elif [ "$vol_percent" -lt 30 ]; then
        icon="󰕿"
    elif [ "$vol_percent" -lt 70 ]; then
        icon="󰖀"
    fi

    notify-send -h string:synchronous:volume -h int:value:"$vol_percent" -t 1200 -a "volume" "$icon Volume: ${vol_percent}%" ""
    (canberra-gtk-play -i audio-volume-change -d "volume-change" 2>/dev/null || pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga 2>/dev/null) &
fi
