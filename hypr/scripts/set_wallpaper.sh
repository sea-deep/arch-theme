#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEFAULT_WALLPAPER="$REPO_DIR/wallpapers/satisfaction_hires.png"
if [ ! -f "$DEFAULT_WALLPAPER" ]; then
    DEFAULT_WALLPAPER="${XDG_PICTURES_DIR:-$HOME/Pictures}/wallpapers/satisfaction_hires.png"
fi
WALLPAPER="${1:-$DEFAULT_WALLPAPER}"
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
