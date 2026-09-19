#!/bin/bash
set +e

# importa variáveis de ambiente do Wayland para o DBus e systemd --user
systemctl --user unset-environment MANGOHUD >/dev/null 2>&1 &
dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP INPUT_METHOD GTK_IM_MODULE QT_IM_MODULE XMODIFIERS SDL_IM_MODULE XCOMPOSEFILE DISABLE_MANGOHUD >/dev/null 2>&1 &
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP INPUT_METHOD GTK_IM_MODULE QT_IM_MODULE XMODIFIERS SDL_IM_MODULE XCOMPOSEFILE DISABLE_MANGOHUD >/dev/null 2>&1 &

# input method (Fcitx5 para cedilha no Wayland / Chromium / apps)
command -v fcitx5 >/dev/null 2>&1 && fcitx5 -d --replace >/dev/null 2>&1 &


# polkit (Noctalia cuidava disso antes; aqui roda um agente próprio)
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &

# portais xdg (drag-and-drop de arquivo, screenshare, etc)
systemctl --user restart xdg-desktop-portal >/dev/null 2>&1 &

# papel de parede — trocado pelo seletor (SUPER+SHIFT+W), que reescreve esta linha
swaybg -i "/home/jagermeister/Pictures/Wallpapers/hancore-blackgold-1.jpg" -m fill >/dev/null 2>&1 &

# notificações
mako >/dev/null 2>&1 &

# barra (iniciada sob supervisão contínua com auto-recuperação)
~/.local/bin/restart-waybar >/dev/null 2>&1 &

# histórico de clipboard (usado no SUPER+V)
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

# auto-lock por inatividade (1 hora) e auto-recuperação pós-suspend
swayidle -w \
    timeout 3600 'swaylock' \
    before-sleep 'swaylock' \
    after-resume "$HOME/.local/bin/restart-waybar" \
    >/dev/null 2>&1 &
