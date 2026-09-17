#!/usr/bin/env bash
# Powermenu via rofi (Amberglow) — SUPER+SHIFT+Q
set -u

shutdown="  Power Off"
reboot="  Reboot"
suspend="  Suspend"
lock="  Lock"
logout="  Log Out"

options="$lock\n$suspend\n$reboot\n$shutdown\n$logout"

chosen="$(printf '%b' "$options" | rofi -dmenu -i -p "󰐥  Power" -theme ~/.config/rofi/powermenu.rasi)"

case "$chosen" in
    "$shutdown") systemctl poweroff ;;
    "$reboot")   systemctl reboot ;;
    "$suspend")  systemctl suspend-then-hibernate ;;
    "$lock")     swaylock ;;
    "$logout")   mmsg dispatch quit ;;
esac
