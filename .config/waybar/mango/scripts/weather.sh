#!/usr/bin/env bash
# Clima via wttr.in, ícone Nerd Font conforme condição + dia/noite.
set -u

json="$(curl -s --max-time 5 'wttr.in/?format=j1')"
if [[ -z "$json" ]]; then
    echo '{"text":"","tooltip":"clima: sem conexão"}'
    exit 0
fi

python3 - "$json" <<'PY'
import json, sys
from datetime import datetime

try:
    data = json.loads(sys.argv[1])
    cur = data["current_condition"][0]
    temp = cur["temp_C"]
    feels = cur["FeelsLikeC"]
    desc = cur["weatherDesc"][0]["value"]
except Exception:
    print(json.dumps({"text": "", "tooltip": "clima: erro ao ler dados"}))
    sys.exit(0)

desc_l = desc.lower()
hour = datetime.now().hour
is_day = 6 <= hour < 18

table = [
    (["thunderstorm"], 0xE30F, 0xE32A),
    (["thundery", "thunder"], 0xE305, 0xE322),
    (["blizzard"], 0xE35F, 0xE360),
    (["snow"], 0xE30A, 0xE327),
    (["sleet"], 0xE3AA, 0xE3AB),
    (["ice pellets", "hail"], 0xE304, 0xE321),
    (["drizzle"], 0xE30B, 0xE328),
    (["light rain", "patchy rain", "rain shower"], 0xE309, 0xE326),
    (["rain"], 0xE308, 0xE325),
    (["fog", "mist"], 0xE303, 0xE346),
    (["overcast"], 0xE312, 0xE37E),
    (["cloudy"], 0xE302, 0xE37B),
    (["clear", "sunny"], 0xE30D, 0xE32B),
]

icon_cp = 0xE374  # weather-na
for keywords, day_cp, night_cp in table:
    if any(k in desc_l for k in keywords):
        icon_cp = day_cp if is_day else night_cp
        break

result = {
    "text": f"{chr(icon_cp)}  {temp}°C",
    "tooltip": f"{desc} · sensação {feels}°C",
}
print(json.dumps(result, ensure_ascii=False))
PY
