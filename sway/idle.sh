#!/bin/bash
# Kill any existing swayidle instance to ensure we only have one running
pkill -x swayidle

STATE_FILE="$HOME/.config/sway/.autosleep_disabled"
if [ -f "$STATE_FILE" ]; then
    exit 0
fi

swayidle -w \
         timeout 180 'brightnessctl -s set 10' resume 'brightnessctl -r' \
         timeout 300 "swaylock -f -i $HOME/Pictures/wallpapers/satisfaction_waybar_blur_lock.png" \
         timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
         timeout 900 'systemctl suspend' \
         before-sleep "swaylock -f -i $HOME/Pictures/wallpapers/satisfaction_waybar_blur_lock.png"
