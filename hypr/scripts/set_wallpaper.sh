#!/usr/bin/env bash
set -euo pipefail
WALLPAPER="${1:-/home/dipak/code/arch-theme/wallpapers/satisfaction_hires.png}"
if [ ! -f "$WALLPAPER" ]; then
    echo "Error: wallpaper file not found: $WALLPAPER" >&2
    exit 1
fi
# Ensure awww-daemon is running
if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    systemctl --user start awww-daemon.service 2>/dev/null || awww-daemon &
    sleep 0.2
fi

# Apply wallpaper with smooth transition
awww img "$WALLPAPER" --transition-type grow --transition-duration 1
