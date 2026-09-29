#!/usr/bin/env bash
# Controla o monitor interno (notebook eDP-1) no MangoWM.
# Uso: toggle-edp.sh [on|off|toggle|status]
set -euo pipefail

MONITOR_CONF="$HOME/.config/mango/monitor.conf"

restart_waybar() {
    # Reinicia o Waybar de forma desacoplada via supervisor resiliente
    if [ -x "$HOME/.local/bin/restart-waybar" ]; then
        "$HOME/.local/bin/restart-waybar" >/dev/null 2>&1 || true
    else
        killall -q waybar 2>/dev/null || true
        pkill -f "$HOME/.config/waybar/mango/scripts/" 2>/dev/null || true
        sleep 0.5
        setsid -f waybar -c "$HOME/.config/waybar/mango/config.jsonc" -s "$HOME/.config/waybar/mango/style.css" >/dev/null 2>&1
    fi
}

is_edp_on() {
    local width
    width="$(mmsg get monitor eDP-1 2>/dev/null | jq -r '.width // 0' 2>/dev/null || echo "0")"
    [ "${width:-0}" -gt 0 ]
}

turn_off() {
    # Proteção: nunca desligar eDP-1 se o monitor externo HDMI não estiver conectado
    if ! grep -qs "^connected$" /sys/class/drm/card*-HDMI-*/status 2>/dev/null; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Monitor" "Apenas o monitor interno está conectado. Não é seguro desligá-lo." -i dialog-warning -t 4000 2>/dev/null || true
        fi
        echo "Aviso: Nenhum monitor externo conectado. eDP-1 mantido ligado." >&2
        return 1
    fi

    cat << 'EOF' > "$MONITOR_CONF"
# Apenas monitor externo maior (HDMI-A-1)
monitorrule=name:HDMI-A-1,width:2560,height:1440,refresh:143.912,x:0,y:0,scale:1
monitorrule=name:eDP-1,width:1920,height:1080,refresh:144.028,x:2560,y:0,scale:1,disable:1
EOF
    mmsg dispatch disable_monitor,eDP-1 >/dev/null 2>&1 || true
    mmsg dispatch reload_config >/dev/null 2>&1 || true

    restart_waybar

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Monitor" "Tela do notebook (eDP-1) desligada.\nUsando apenas HDMI-A-1 (2560x1440)." -i display -t 3000
    fi
    echo "eDP-1 desligado. Monitor HDMI-A-1 ativo em (0,0)."
}

turn_on() {
    cat << 'EOF' > "$MONITOR_CONF"
# Layout dual-monitor (notebook eDP-1 + monitor externo HDMI-A-1)
monitorrule=name:HDMI-A-1,width:2560,height:1440,refresh:143.912,x:1920,y:0,scale:1
monitorrule=name:eDP-1,width:1920,height:1080,refresh:144.028,x:0,y:126,scale:1
EOF
    mmsg dispatch enable_monitor,eDP-1 >/dev/null 2>&1 || true
    mmsg dispatch reload_config >/dev/null 2>&1 || true

    restart_waybar

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Monitor" "Tela do notebook (eDP-1) ligada.\nModo dual monitor restaurado." -i display -t 3000
    fi
    echo "eDP-1 ligado. Modo dual monitor restaurado."
}

action="${1:-toggle}"

case "$action" in
    off|disable)
        turn_off
        ;;
    on|enable)
        turn_on
        ;;
    toggle)
        if is_edp_on; then
            turn_off
        else
            turn_on
        fi
        ;;
    status)
        if is_edp_on; then
            echo "eDP-1: LIGADO (1920x1080)"
        else
            echo "eDP-1: DESLIGADO"
        fi
        ;;
    *)
        echo "Uso: $0 [on|off|toggle|status]" >&2
        exit 1
        ;;
esac
