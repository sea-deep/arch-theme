#!/usr/bin/env bash
# caps_listener.sh - monitors CapsLock LED state via sysfs
set -euo pipefail

get_state() {
    for f in /sys/class/leds/*capslock*/brightness; do
        if [[ -r "$f" ]]; then
            val=$(<"$f")
            if [[ "$val" == "1" ]]; then
                echo "1"
                return
            fi
        fi
    done
    echo "0"
}

# Output initial state immediately
current="$(get_state)"
echo "$current"

# Check periodically for state changes
while true; do
    sleep 0.15
    new_state="$(get_state)"
    if [[ "$new_state" != "$current" ]]; then
        current="$new_state"
        echo "$current"
    fi
done
