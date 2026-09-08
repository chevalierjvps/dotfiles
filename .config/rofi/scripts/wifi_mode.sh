#!/usr/bin/env bash
# Rofi script-mode: Wi-Fi (nmcli). Adicionar ao modi do rofi como
# "wifi:~/.config/rofi/scripts/wifi_mode.sh"
set -u

ICON_LOCK=$''
ICON_CHECK=$''
ICON_SIGNAL=$''

list() {
    echo -en "\0prompt\x1fwifi\n"
    local radio
    radio="$(nmcli radio wifi)"
    if [[ "$radio" == "enabled" ]]; then
        printf 'Wi-Fi: ligado (clique pra desligar)\0info\x1f__toggle_radio\n'
    else
        printf 'Wi-Fi: desligado (clique pra ligar)\0info\x1f__toggle_radio\n'
        return
    fi
    printf 'Escanear novamente\0info\x1f__rescan\n'

    nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | while IFS=: read -r inuse signal sec ssid; do
        [[ -z "$ssid" ]] && continue
        local mark=""
        [[ "$inuse" == "*" ]] && mark="$ICON_CHECK "
        local lock=""
        [[ -n "$sec" && "$sec" != "--" ]] && lock="$ICON_LOCK "
        printf '%s%s%s (%s%%)\0info\x1f%s\n' "$mark" "$lock" "$ssid" "$signal" "$ssid"
    done
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" ]]; then
    case "$info" in
        __toggle_radio)
            nmcli radio wifi toggle
            sleep 1
            ;;
        __rescan)
            nmcli dev wifi rescan >/dev/null 2>&1
            sleep 1
            ;;
        "")
            ;;
        *)
            ssid="$info"
            state="$(nmcli -t -f IN-USE,SSID dev wifi list 2>/dev/null | awk -F: -v s="$ssid" '$2==s{print $1}')"
            if [[ "$state" == "*" ]]; then
                nmcli con down id "$ssid" >/dev/null 2>&1
            elif nmcli -t -f NAME con show 2>/dev/null | grep -qxF "$ssid"; then
                nmcli con up id "$ssid" >/dev/null 2>&1
            else
                sec="$(nmcli -t -f SECURITY,SSID dev wifi list 2>/dev/null | awk -F: -v s="$ssid" '$2==s{print $1}')"
                if [[ -n "$sec" && "$sec" != "--" ]]; then
                    pass="$(rofi -dmenu -password -p "Senha: $ssid" -theme ~/.config/rofi/amberglow.rasi)"
                    [[ -z "$pass" ]] && { list; exit 0; }
                    nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1
                else
                    nmcli dev wifi connect "$ssid" >/dev/null 2>&1
                fi
            fi
            ;;
    esac
fi

list
