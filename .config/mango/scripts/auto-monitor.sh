#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ⚡ AUTO-MONITOR SAFEGUARD (MANGOWM) ⚡
#  Detecta se o monitor HDMI está presente ou ausente e ajusta o monitor.conf
#  automaticamente, garantindo que o eDP-1 NUNCA fique desligado ao desplugá-lo.
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

MONITOR_CONF="$HOME/.config/mango/monitor.conf"

check_and_apply() {
    local is_hdmi_connected=false
    if grep -qs "^connected$" /sys/class/drm/card*-HDMI-*/status 2>/dev/null; then
        is_hdmi_connected=true
    fi

    if [ "$is_hdmi_connected" = false ]; then
        # HDMI DESCONECTADO: O eDP-1 precisa obrigatoriamente estar ligado na posição (0,0)
        # Se monitor.conf tiver disable:1 no eDP-1 ou eDP-1 não estiver em (0,0), reescreve
        if grep -q "disable:1" "$MONITOR_CONF" 2>/dev/null || ! grep -q "name:eDP-1.*x:0,y:0" "$MONITOR_CONF" 2>/dev/null; then
            cat << 'EOF' > "$MONITOR_CONF"
# Layout single-monitor automático (HDMI ausente - tela do notebook eDP-1 ativa)
monitorrule=name:eDP-1,width:1920,height:1080,refresh:144.028,x:0,y:0,scale:1
EOF
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch enable_monitor,eDP-1 >/dev/null 2>&1 || true
                mmsg dispatch reload_config >/dev/null 2>&1 || true
            fi
            
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Monitor" "HDMI desconectado. Tela do notebook (eDP-1) ativada como primária." -i display -t 3000 2>/dev/null || true
            fi
            "$HOME/.local/bin/restart-waybar" >/dev/null 2>&1 || true
        fi
    else
        # HDMI CONECTADO: se monitor.conf estava em single-monitor sem HDMI definido, restaura dual monitor
        if ! grep -q "name:HDMI-A-1" "$MONITOR_CONF" 2>/dev/null; then
            cat << 'EOF' > "$MONITOR_CONF"
# Layout dual-monitor (notebook eDP-1 + monitor externo HDMI-A-1)
monitorrule=name:HDMI-A-1,width:2560,height:1440,refresh:143.912,x:1920,y:0,scale:1
monitorrule=name:eDP-1,width:1920,height:1080,refresh:144.028,x:0,y:126,scale:1
EOF
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch enable_monitor,eDP-1 >/dev/null 2>&1 || true
                mmsg dispatch reload_config >/dev/null 2>&1 || true
            fi
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Monitor" "HDMI conectado. Modo dual monitor restaurado." -i display -t 3000 2>/dev/null || true
            fi
            "$HOME/.local/bin/restart-waybar" >/dev/null 2>&1 || true
        fi
    fi
}

# Se chamado como daemon/watch, monitora eventos DRM em background
if [ "${1:-}" = "watch" ]; then
    check_and_apply
    # Escuta eventos de udev DRM
    udevadm monitor --kernel --subsystem-match=drm 2>/dev/null | while read -r line; do
        if echo "$line" | grep -qi "change"; then
            sleep 0.5
            check_and_apply
        fi
    done
else
    check_and_apply
fi
