#!/usr/bin/env bash
# Rofi script-mode: Audio & Output Manager + Pavucontrol launcher
set -u

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" && -n "$info" ]]; then
    case "$info" in
        __pavucontrol)
            setsid pavucontrol >/dev/null 2>&1 &
            exit 0
            ;;
        __toggle_mute)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ~/.config/mango/scripts/volume.sh up >/dev/null 2>&1 || true
            ;;
        __toggle_mic)
            ~/.config/mango/scripts/volume.sh mic-mute >/dev/null 2>&1 || true
            ;;
        __vol_*)
            pct="${info#__vol_}"
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${pct}%"
            ~/.config/mango/scripts/volume.sh up >/dev/null 2>&1 || true
            ;;
        sink_*)
            id="${info#sink_}"
            wpctl set-default "$id"
            notify-send -t 1500 -a "volume" "󰕾 Audio Output" "Switched default output to device #$id"
            ;;
        source_*)
            id="${info#source_}"
            wpctl set-default "$id"
            notify-send -t 1500 -a "volume" "󰍬 Audio Input" "Switched default microphone to device #$id"
            ;;
    esac
    exit 0
fi

list() {
    echo -en "\0prompt\x1faudio\n"
    printf '󰓃  Launch Pavucontrol (Audio GUI)\0info\x1f__pavucontrol\n'
    printf '󰝟  Toggle Output Mute\0info\x1f__toggle_mute\n'
    printf '󰍬  Toggle Microphone Mute\0info\x1f__toggle_mic\n'
    printf '󰕾  Set Volume 100%%\0info\x1f__vol_100\n'
    printf '󰖀  Set Volume 75%%\0info\x1f__vol_75\n'
    printf '󰕿  Set Volume 50%%\0info\x1f__vol_50\n'
    printf '󰕿  Set Volume 25%%\0info\x1f__vol_25\n'

    # List outputs
    printf '─── Output Devices ───\0nonselectable\x1ftrue\n'
    wpctl status 2>/dev/null | awk '/├─ Sinks:/{flag=1; next} /├─ Sources:/{flag=0} flag' | while read -r line; do
        if [[ "$line" =~ ([*]?)[[:space:]]*([0-9]+)\.[[:space:]]*(.+)[[:space:]]*\[vol: ]]; then
            active="${BASH_REMATCH[1]}"
            id="${BASH_REMATCH[2]}"
            name="$(echo "${BASH_REMATCH[3]}" | xargs)"
            prefix="  󰕾"
            [[ -n "$active" ]] && prefix="● 󰕾"
            printf '%s %s [#%s]\0info\x1fsink_%s\n' "$prefix" "$name" "$id" "$id"
        fi
    done

    # List inputs
    printf '─── Input Devices ───\0nonselectable\x1ftrue\n'
    wpctl status 2>/dev/null | awk '/├─ Sources:/{flag=1; next} /├─ Filters:/{flag=0} flag' | while read -r line; do
        if [[ "$line" =~ ([*]?)[[:space:]]*([0-9]+)\.[[:space:]]*(.+)[[:space:]]*\[vol: ]]; then
            active="${BASH_REMATCH[1]}"
            id="${BASH_REMATCH[2]}"
            name="$(echo "${BASH_REMATCH[3]}" | xargs)"
            prefix="  󰍬"
            [[ -n "$active" ]] && prefix="● 󰍬"
            printf '%s %s [#%s]\0info\x1fsource_%s\n' "$prefix" "$name" "$id" "$id"
        fi
    done
}

list
