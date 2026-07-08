#!/bin/bash
PREV_STATE=""

while true; do
    if grep -q '1' /sys/class/leds/*capslock/brightness 2>/dev/null; then
        STATE="ON"
    else
        STATE="OFF"
    fi
    
    if [ "$STATE" != "$PREV_STATE" ]; then
        if [ "$STATE" = "ON" ]; then
            echo '{"text": "<span color='\''#f7768e'\''> 󰪛 </span>", "tooltip": "Caps Lock is ON"}'
        else
            echo '{"text": "", "tooltip": "Caps Lock is OFF"}'
        fi
        PREV_STATE="$STATE"
    fi
    sleep 0.1
done
