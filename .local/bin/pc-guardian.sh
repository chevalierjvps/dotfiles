#!/usr/bin/env bash
# PC Performance & Memory Leak Guardian
# Executado automaticamente a cada 2 minutos via systemd --user (pc-guardian.timer)
set -u

# 1. Impede que o plugin Flutter MCP recrie o dart-mcp-server na pasta home (evita 2.5 GB RAM + 70% CPU)
FLUTTER_MCP="$HOME/.gemini/config/plugins/flutter/mcp_config.json"
if [ -f "$FLUTTER_MCP" ]; then
    if grep -q '"dart-mcp-server"' "$FLUTTER_MCP" 2>/dev/null; then
        echo '{"mcpServers": {}}' > "$FLUTTER_MCP"
    fi
fi

# Encerra qualquer dart language-server órfão rodando na home ou na pasta do plugin
for pid in $(pgrep -f "dart.*language-server" 2>/dev/null); do
    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
    if [[ "$cwd" == "$HOME" || "$cwd" == "$HOME/Downloads" || "$cwd" == *".gemini/config/plugins/flutter"* ]]; then
        kill -9 "$pid" 2>/dev/null || true
    fi
done

# 2. Garante que o indexador localsearch-3 (vazamento de 6.6 GB) nunca rode
pkill -9 -x localsearch-3 2>/dev/null || true

# 3. Proteção contra vazamento de memória (RAM + Swap > 1.4 GB) em apps de bandeja (ZapZap, Stremio)
check_and_cap_leak() {
    local pattern="$1"
    local max_kb="$2"
    for pid in $(pgrep -f "$pattern" 2>/dev/null); do
        if [ -r "/proc/$pid/status" ]; then
            local rss swap total
            rss=$(awk '/^VmRSS:/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
            swap=$(awk '/^VmSwap:/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
            total=$(( ${rss:-0} + ${swap:-0} ))
            if [ "$total" -gt "$max_kb" ]; then
                kill -15 "$pid" 2>/dev/null || true
            fi
        fi
    done
}

# Limita QtWebEngineProcess (ZapZap/Stremio) a 1.4 GB (1468000 KB) para nunca mais vazar 5.1 GB na Swap
check_and_cap_leak "QtWebEngineProcess" 1468000

# 4. Descarrega llama-server (Ollama) caso fique ocioso (< 1% CPU) segurando > 1 GB na memória/Swap
for pid in $(pgrep -f "llama-server" 2>/dev/null); do
    if [ -r "/proc/$pid/status" ]; then
        rss=$(awk '/^VmRSS:/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
        swap=$(awk '/^VmSwap:/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
        total=$(( ${rss:-0} + ${swap:-0} ))
        cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{print int($1)}' || echo 0)
        if [ "$total" -gt 1048576 ] && [ "${cpu:-0}" -lt 1 ]; then
            kill -15 "$pid" 2>/dev/null || true
        fi
    fi
done

# 5. Gerenciamento inteligente do perfil de energia:
# Mantém 'balanced' no uso normal (evita travar a CPU a 4.1 GHz / 92 °C),
# mas respeita se algum jogo pesado (Horizon, Sober, Steam/Proton) estiver aberto.
if command -v powerprofilesctl >/dev/null 2>&1; then
    current_profile=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    if [ "$current_profile" = "performance" ]; then
        if ! pgrep -f "horizon-client|Sober|sober|wine64-preloader|reaper" >/dev/null 2>&1; then
            powerprofilesctl set balanced 2>/dev/null || true
        fi
    fi
fi
