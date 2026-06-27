#!/bin/bash

# If pavucontrol is already running, kill it and clean up the Escape binding
if pgrep -x pavucontrol > /dev/null; then
    pkill -x pavucontrol
    swaymsg unbindsym Escape 2>/dev/null
    exit 0
fi

# Bind Escape globally to kill pavucontrol. When pavucontrol is killed, the script 
# resumes and executes the cleanup (unbindsym) automatically.
swaymsg 'bindsym Escape exec pkill pavucontrol'

# Launch pavucontrol and wait for it to close
pavucontrol

# If pavucontrol is closed by other means (clicking X, or the Waybar button again),
# ensure the Escape binding is cleaned up so we don't break the keyboard.
swaymsg unbindsym Escape 2>/dev/null
