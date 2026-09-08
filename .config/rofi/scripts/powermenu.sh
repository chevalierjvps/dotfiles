#!/usr/bin/env bash
# Powermenu via rofi (Amberglow) — SUPER+SHIFT+Q
set -u

shutdown="  Desligar"
reboot="  Reiniciar"
suspend="  Suspender"
lock="  Bloquear"
logout="  Sair"

options="$lock\n$suspend\n$reboot\n$shutdown\n$logout"

chosen="$(printf '%b' "$options" | rofi -dmenu -i -p "Energia" -theme ~/.config/rofi/powermenu.rasi)"

case "$chosen" in
    "$shutdown") systemctl poweroff ;;
    "$reboot")   systemctl reboot ;;
    "$suspend")  systemctl suspend-then-hibernate ;;
    "$lock")     swaylock ;;
    "$logout")   mmsg dispatch quit ;;
esac
