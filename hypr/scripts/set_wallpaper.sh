#!/usr/bin/env bash
set -euo pipefail
WALLPAPER="${1:-/home/dipak/code/arch-theme/wallpapers/satisfaction_hires.png}"
if [ ! -f "$WALLPAPER" ]; then
    echo "Error: wallpaper file not found: $WALLPAPER" >&2
    exit 1
fi
pkill -x swaybg 2>/dev/null || true
sleep 0.1

if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl eval "hl.dispatch(hl.dsp.exec_cmd('swaybg -i \"$WALLPAPER\" -m fill'))" >/dev/null 2>&1
else
    nohup swaybg -i "$WALLPAPER" -m fill >/dev/null 2>&1 &
fi
