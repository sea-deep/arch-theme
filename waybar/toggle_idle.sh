#!/bin/bash
STATE_FILE="$HOME/.config/sway/.autosleep_disabled"

if pgrep -x swayidle > /dev/null; then
    pkill -x swayidle
    touch "$STATE_FILE"
    notify-send -u low -t 2000 "Autosleep Disabled" "Screen will stay awake."
else
    if [ -x "$HOME/.config/sway/idle.sh" ]; then
        rm -f "$STATE_FILE"
        "$HOME/.config/sway/idle.sh" &
        notify-send -u low -t 2000 "Autosleep Enabled" "Normal power management restored."
    else
        notify-send -u critical -t 4000 "Error" "Idle script ($HOME/.config/sway/idle.sh) is missing or not executable."
    fi
fi

# Instantly trigger Waybar to update the autosleep indicator
pkill -RTMIN+10 waybar
