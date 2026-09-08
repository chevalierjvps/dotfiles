#!/usr/bin/env bash
# Substitui wlr/taskbar (idem, não compilado) por um título da janela focada,
# no estilo status-bar de dwm — só aparece na barra do monitor onde a janela
# focada realmente está.
set -u
OUTPUT="${WAYBAR_OUTPUT_NAME:-$(mmsg get all-monitors | jq -r '.monitors[0].name')}"

mmsg watch focusing-client | while IFS= read -r line; do
    jq -c --arg out "$OUTPUT" '
        if (. == null) or (.monitor != $out) then
            {text: "", tooltip: ""}
        else
            (.title // "") as $t
            | (if ($t | length) > 60 then ($t[0:60] + "…") else $t end) as $short
            | {text: $short, tooltip: (.appid // "")}
        end
    ' <<<"$line"
done
