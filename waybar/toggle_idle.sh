#!/bin/bash
if pgrep -x swayidle > /dev/null; then
    pkill -x swayidle
    notify-send -u low -t 2000 "Autosleep Disabled" "Screen will stay awake."
else
    if [ -x "$HOME/.config/sway/idle.sh" ]; then
        "$HOME/.config/sway/idle.sh" &
        notify-send -u low -t 2000 "Autosleep Enabled" "Normal power management restored."
    else
        notify-send -u critical -t 4000 "Error" "Idle script ($HOME/.config/sway/idle.sh) is missing or not executable."
    fi
fi
