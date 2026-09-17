#!/usr/bin/env bash
# Notification bell: active count + Do Not Disturb status
set -u

bell=$''
bell_slash=$''

while true; do
    count="$(makoctl list -j 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"
    count="${count:-0}"

    if makoctl mode 2>/dev/null | grep -qx "do-not-disturb"; then
        printf '{"text":"%s","tooltip":"Do Not Disturb: ON","class":"dnd"}\n' "$bell_slash"
    elif (( count > 0 )); then
        printf '{"text":"%s %d","tooltip":"%d active notification(s)","class":"active"}\n' "$bell" "$count" "$count"
    else
        printf '{"text":"%s","tooltip":"No notifications","class":"empty"}\n' "$bell"
    fi

    sleep 2
done
