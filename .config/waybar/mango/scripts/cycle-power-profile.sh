#!/bin/bash
# Alterna performance -> balanced -> power-saver -> performance
current=$(powerprofilesctl get)
case "$current" in
    performance) next=balanced ;;
    balanced) next=power-saver ;;
    *) next=performance ;;
esac
powerprofilesctl set "$next"
notify-send -a "Power" "Perfil de energia" "$next" 2>/dev/null
