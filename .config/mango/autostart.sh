#!/bin/bash
set +e

# polkit (Noctalia cuidava disso antes; aqui roda um agente próprio)
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &

# portais xdg (drag-and-drop de arquivo, screenshare, etc)
systemctl --user restart xdg-desktop-portal >/dev/null 2>&1 &

# papel de parede — trocado pelo seletor (SUPER+SHIFT+W), que reescreve esta linha
swaybg -i "/home/jagermeister/Pictures/Wallpapers/hancore-blackgold-1.jpg" -m fill >/dev/null 2>&1 &

# notificações
mako >/dev/null 2>&1 &

# barra
waybar -c ~/.config/waybar/mango/config.jsonc -s ~/.config/waybar/mango/style.css >/dev/null 2>&1 &

# histórico de clipboard (usado no SUPER+V)
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

# auto-lock por inatividade (mesmo tempo configurado no Noctalia: 10min)
swayidle -w \
    timeout 600 'swaylock' \
    before-sleep 'swaylock' \
    >/dev/null 2>&1 &
