#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.config/quickshell/state/brightness.txt"
mkdir -p "$(dirname "$STATE_FILE")"

case "${1:-get}" in
    set)
        val="${2:-100%}"
        brightnessctl set "$val" -q
        brightnessctl get > "$STATE_FILE"
        ;;
    restore)
        if [[ -f "$STATE_FILE" ]] && [[ -s "$STATE_FILE" ]]; then
            val="$(cat "$STATE_FILE" 2>/dev/null || true)"
            if [[ -n "$val" ]]; then
                brightnessctl set "$val" -q
            fi
        elif comp_val="$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n 1 || true)"; [[ -n "$comp_val" ]]; then
            brightnessctl set "$comp_val" -q
            echo "$comp_val" > "$STATE_FILE"
        fi
        ;;
    save)
        brightnessctl get > "$STATE_FILE"
        ;;
    step_up)
        step="${2:-5%}"
        brightnessctl set "${step}+" -q
        brightnessctl get > "$STATE_FILE"
        ;;
    step_down)
        step="${2:-5%}"
        brightnessctl set "${step}-" -q
        brightnessctl get > "$STATE_FILE"
        ;;
    *)
        brightnessctl get
        ;;
esac
