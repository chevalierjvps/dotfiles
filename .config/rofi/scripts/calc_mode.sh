#!/usr/bin/env bash
# Rofi script-mode: calculadora via qalc (libqalculate). Digite uma expressão
# e Enter calcula; Enter de novo no resultado copia pro clipboard.
set -u

retv="${ROFI_RETV:-0}"

case "$retv" in
    1)
        # Enter em cima de um resultado já calculado -> copia
        info="${ROFI_INFO:-}"
        [[ -n "$info" ]] && printf '%s' "$info" | wl-copy
        exit 0
        ;;
    2)
        # Enter em cima de texto digitado (não bate com nenhuma linha) -> calcula
        echo -en "\0prompt\x1fcalc\n"
        expr="$1"
        result="$(qalc -t "$expr" 2>/dev/null)"
        if [[ -z "$result" ]]; then
            printf 'expressão inválida\0nonselectable\x1ftrue\n'
        else
            printf '%s = %s\0info\x1f%s\n' "$expr" "$result" "$result"
        fi
        ;;
    *)
        echo -en "\0prompt\x1fcalc\n"
        echo -en "\0message\x1fDigite uma expressão e pressione Enter\n"
        ;;
esac
