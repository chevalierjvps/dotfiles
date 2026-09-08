#!/usr/bin/env bash
# Rofi script-mode: Bluetooth (bluetoothctl). Adicionar ao modi do rofi como
# "bt:~/.config/rofi/scripts/bt_mode.sh"
set -u

ICON_ON=$'󰂱'
ICON_OFF=$'󰂲'
ICON_DEVICE=$''

list() {
    echo -en "\0prompt\x1fbluetooth\n"
    local powered
    powered="$(bluetoothctl show | awk -F': ' '/Powered/{print $2}')"
    if [[ "$powered" == "yes" ]]; then
        printf '%s Bluetooth: ligado (clique pra desligar)\0info\x1f__toggle_power\n' "$ICON_ON"
    else
        printf '%s Bluetooth: desligado (clique pra ligar)\0info\x1f__toggle_power\n' "$ICON_OFF"
        return
    fi
    printf 'Escanear novos dispositivos (10s)\0info\x1f__scan\n'

    bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do
        local connected
        connected="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/^\s*Connected/{print $2}')"
        if [[ "$connected" == "yes" ]]; then
            printf '%s %s (conectado)\0info\x1f%s\n' "$ICON_DEVICE" "$name" "$mac"
        else
            printf '%s %s\0info\x1f%s\n' "$ICON_DEVICE" "$name" "$mac"
        fi
    done
}

retv="${ROFI_RETV:-0}"
info="${ROFI_INFO:-}"

if [[ "$retv" == "1" ]]; then
    case "$info" in
        __toggle_power)
            powered="$(bluetoothctl show | awk -F': ' '/Powered/{print $2}')"
            if [[ "$powered" == "yes" ]]; then
                bluetoothctl power off >/dev/null 2>&1
            else
                bluetoothctl power on >/dev/null 2>&1
            fi
            sleep 1
            ;;
        __scan)
            bluetoothctl --timeout 10 scan on >/dev/null 2>&1
            ;;
        "")
            ;;
        *)
            mac="$info"
            connected="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/^\s*Connected/{print $2}')"
            if [[ "$connected" == "yes" ]]; then
                bluetoothctl disconnect "$mac" >/dev/null 2>&1
            else
                bluetoothctl connect "$mac" >/dev/null 2>&1
            fi
            sleep 1
            ;;
    esac
fi

list
