#!/bin/bash

# If pavucontrol is already running, kill it (toggle behavior for the Waybar button)
if pgrep -x pavucontrol > /dev/null; then
    pkill -x pavucontrol
    exit 0
fi

# Launch pavucontrol in the background
pavucontrol &
PAVU_PID=$!

# Wait half a second for pavucontrol to actually map to the screen and grab focus.
# Without this delay, Waybar fires a focus event BEFORE pavucontrol appears, instantly killing it.
sleep 0.5

# Use swaymsg to listen to window focus events.
# We unbuffer jq so it processes events in real-time.
swaymsg -t subscribe -m '["window"]' | jq --unbuffered -c '.' | while read -r event; do
    change=$(echo "$event" | jq -r '.change')
    if [[ "$change" == "focus" ]]; then
        # Extract the app_id or class of the window that just received focus
        app_id=$(echo "$event" | jq -r '.container.app_id // .container.window_properties.class // empty')
        
        # If the window that just got focus is NOT pavucontrol, close the popup!
        if [[ "$app_id" != "org.pulseaudio.pavucontrol" && "$app_id" != "pavucontrol" ]]; then
            pkill -x pavucontrol
            break
        fi
    fi
done
