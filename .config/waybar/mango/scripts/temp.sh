#!/bin/bash
t=$(sensors 2>/dev/null | awk '/^Package id 0:/ {gsub(/[+°C]/,"",$4); print int($4)}')
if [ -z "$t" ]; then
    echo '{"text": "N/A", "tooltip": "sensor indisponível"}'
    exit 0
fi
class="normal"
if [ "$t" -ge 85 ]; then class="critical"; elif [ "$t" -ge 70 ]; then class="warning"; fi
echo "{\"text\": \"${t}°C\", \"tooltip\": \"CPU package: ${t}°C\", \"class\": \"${class}\"}"
