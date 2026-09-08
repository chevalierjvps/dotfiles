#!/usr/bin/env bash
# Substitui wlr/workspaces (não compilado neste build do waybar/Arch) por um
# indicador de tags nativo do mango, via mmsg. Emite uma linha JSON a cada
# mudança de estado das tags do output desta barra.
set -u
OUTPUT="${WAYBAR_OUTPUT_NAME:-$(mmsg get all-monitors | jq -r '.monitors[0].name')}"

mmsg watch tags "$OUTPUT" | while IFS= read -r line; do
    jq -c '
        (.tags | map(
            if .is_urgent then
                "<span foreground=\"#d9483d\">\(.index)</span>"
            elif .is_active then
                "<span background=\"#e8952d\" foreground=\"#1a150f\"> \(.index) </span>"
            elif .client_count > 0 then
                "<span foreground=\"#d8c48a\">\(.index)</span>"
            else
                "<span foreground=\"#5a4f3d\">\(.index)</span>"
            end
        ) | join(" ")) as $text
        | {text: $text, tooltip: "tag \(.active_tags[0] // 1)"}
    ' <<<"$line"
done
