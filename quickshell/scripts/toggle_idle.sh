#!/bin/bash
STATE_FILE="$HOME/.config/hypr/.autosleep_disabled"

if pgrep -x hypridle > /dev/null; then
    pkill -x hypridle
    touch "$STATE_FILE"
    notify-send -u low -t 2000 "Autosleep Disabled" "Screen will stay awake."
else
    rm -f "$STATE_FILE"
    hypridle &
    notify-send -u low -t 2000 "Autosleep Enabled" "Normal power management restored."
fi
